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
    @gs2.user = @archer
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
    assert_response :ok
    get is_duplicate_guess_path({ id: @gs1.id, word: "nymph"})
    assert_response :ok
    assert_equal false, JSON.parse(response.body)['status']
    get is_duplicate_guess_path({ id: @gs1.id, word: "fjord"})
    assert_response :ok
    assert_equal true, JSON.parse(response.body)['status']
  end
end
