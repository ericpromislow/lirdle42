require "test_helper"

class GameStatesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:user1)
    @archer = users(:archer)
    @user2 = users(:user2)
    @game = games(:game1)
    @gs1 = game_states(:gs1)
    @gs2 = game_states(:gs2)
    @gs1.game = @gs2.game = @game
    @gs1.user = @user
    @gs2.user = @user2
    @gs1.save!
    @gs2.save!
  end

  test "non-logged-in-user can't update a game state" do
    patch game_state_url(@gs1), params: { state: 99 }
    assert_redirected_to login_url
  end

  test "logged-in-user can't change a wordlist of an existing game" do
    log_in_as(@user)
    before = @gs1.candidateWords
    patch game_state_url(@gs1), params: { candidateWords: "smerdjakov"}
    @gs1.reload
    assert_equal before, @gs1.candidateWords
  end

  test "logged-in-user can change other fields in an existing game" do
    log_in_as(@user)
    patch game_state_url(@gs1), params: { finalWord: "coupe" }
    assert_redirected_to game_path(@game)
    @gs1.reload
    assert_equal 1, @gs1.state
    assert_equal "coupe", @gs1.finalWord
  end

  test "admin user can change other player's fields" do
    log_in_as(@user)
    patch game_state_url(@gs2), params: { state: 99, wordIndex: 99, finalWord: "99" }
    assert_redirected_to game_path(@game)
    @gs2.reload
    assert_equal 1, @gs2.state
    assert_equal "99", @gs2.finalWord
  end

  test "logged-in-user can't change other player's fields" do
    log_in_as(@user2)
    patch game_state_url(@gs1), params: { state: 99, wordIndex: 99, finalWord: "99" }
    assert_redirected_to root_url
    @gs1.reload
    assert_not_equal 99, @gs1.state
    assert_not_equal 99, @gs1.wordIndex
    assert_not_equal "99", @gs1.finalWord
  end

  test "found-duplicate-guess" do
    log_in_as(@user)
    @gs1.update_attribute(:finalWord, "motel")
    @gs2.update_attribute(:finalWord, "clump")
    post guesses_url({ game_state_id: @gs1.id, word: "fjord" })
    assert_redirected_to game_path(@game)
    get is_duplicate_guess_path({ id: @gs1.id, word: "nymph"})
    assert_response :ok
    assert_equal false, JSON.parse(response.body)['status']
    get is_duplicate_guess_path({ id: @gs1.id, word: "fjord"})
    assert_response :ok
    assert_equal true, JSON.parse(response.body)['status']
  end

  test "lying changes states to 5 and then back to 2" do
    @gs1.update_attribute(:finalWord, "motel")
    @gs2.update_attribute(:finalWord, "clump")
    log_in_as(@user)
    post guesses_url({ game_state_id: @gs1.id, word: "fjord" })
    assert_redirected_to game_path(@game)
    log_in_as(@user2)
    post guesses_url({ game_state_id: @gs2.id, word: "place" })
    assert_redirected_to game_path(@game)
    @gs1.reload
    @gs2.reload
    assert_equal [4, 4], [@gs1.state, @gs2.state]
    log_in_as(@user)
    patch game_state_url(@gs1, lie: "1:1:2:green")
    assert_redirected_to game_path(@game)
    @gs1.reload
    @gs2.reload
    last_guess = @gs2.guesses.last
    assert_equal [5, 4, "0:1:0:0:1", 1, 2], [@gs1.state, @gs2.state, last_guess.score, last_guess.liePosition, last_guess.lieColor ]

    log_in_as(@user2)
    # perturb 'fjord' guessing 'clump'
    patch game_state_url(@gs2, lie: "2:0:1:yellow")
    assert_redirected_to game_path(@game)
    @gs1.reload
    @gs2.reload
    last_guess = @gs1.guesses.last
    assert_equal [2, 2, "0:0:0:0:0", 2, 1], [@gs1.state, @gs2.state, last_guess.score, last_guess.liePosition, last_guess.lieColor ]

  end

  test "ties go through states [2,2] => [6,2] => [7,7]" do
    common_setup
    # user1 target: clump, user2 target: motel
    log_in_as(@user)
    post guesses_url({ game_state_id: @gs1.id, word: "clump" })
    assert_redirected_to game_path(@game)
    @gs1.reload
    @gs2.reload
    assert_equal [6, 2], [@gs1.state, @gs2.state]

    log_in_as(@user2)
    post guesses_url({ game_state_id: @gs2.id, word: "motel" })
    assert_redirected_to game_path(@game)
    @gs1.reload
    @gs2.reload
    assert_equal [7, 7], [@gs1.state, @gs2.state]
  end

  test "first-winner goes through states [2,2] => [6,2] => [8,9]" do
    common_setup
    # user1 target: clump, user2 target: motel
    log_in_as(@user)
    post guesses_url({ game_state_id: @gs1.id, word: "clump" })
    assert_redirected_to game_path(@game)
    @gs1.reload
    @gs2.reload
    assert_equal [6, 2], [@gs1.state, @gs2.state]

    log_in_as(@user2)
    post guesses_url({ game_state_id: @gs2.id, word: "stick" })
    assert_redirected_to game_path(@game)
    @gs1.reload
    @gs2.reload
    assert_equal [8,9], [@gs1.state, @gs2.state]
  end

  test "second-winner goes through states [2,2] => [3,2] => [9,8]" do
    common_setup
    # user1 target: clump, user2 target: motel
    log_in_as(@user)
    post guesses_url({ game_state_id: @gs1.id, word: "hotel" })
    assert_redirected_to game_path(@game)
    @gs1.reload
    @gs2.reload
    assert_equal [3, 2], [@gs1.state, @gs2.state]

    log_in_as(@user2)
    post guesses_url({ game_state_id: @gs2.id, word: "motel" })
    assert_redirected_to game_path(@game)
    @gs1.reload
    @gs2.reload
    assert_equal [9,8], [@gs1.state, @gs2.state]
  end

  def common_setup
    @gs1.update_attribute(:finalWord, "motel")
    @gs2.update_attribute(:finalWord, "clump")
    log_in_as(@user)
    post guesses_url({game_state_id: @gs1.id, word: "fjord"})
    post guesses_url({game_state_id: @gs1.id, word: "nymph"})
    post guesses_url({game_state_id: @gs1.id, word: "boxes"})
    log_in_as(@user2)
    post guesses_url({game_state_id: @gs2.id, word: "spawn"})
    post guesses_url({game_state_id: @gs2.id, word: "dirty"})
    post guesses_url({game_state_id: @gs2.id, word: "fleck"})
    @gs1.reload
    @gs2.reload
    @gs1.update_attribute(:state, 2)
    @gs2.update_attribute(:state, 2)
  end
end
