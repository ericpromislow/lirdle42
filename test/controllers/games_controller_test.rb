require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:user1)
    @archer = users(:archer)
    @user2 = users(:user2)
    @game = games(:game1)
    @gs1 = game_states(:gs1)
    @gs1.playerID = @user.id
    @gs2 = game_states(:gs2)
    @gs2.playerID = @archer.id
    @game.gameStateA = @gs1.id
    @game.gameStateB = @gs2.id
    @gs1.game = @gs2.game = @game
    @gs1.save!
    @gs2.save!
    @game.save!
  end
  test "need to be logged-in as admin to get index" do
    get games_url
    assert_redirected_to login_url
    log_in_as(@user2)
    get games_url
    assert_redirected_to root_url
    log_in_as(@user)
    get games_url
    assert_response :success
  end

  test "need to be logged in to create a game" do
    assert_difference('Game.count', 0) do
      post games_url(playerA: @user.id, playerB: @archer.id)
    end
    assert_redirected_to login_url
  end

  test "logged in non-admin user can't create a game for others" do
    log_in_as(@user2)
    assert_difference('Game.count', 0) do
      post games_url(playerA: @user.id, playerB: @archer.id)
    end
    assert_redirected_to root_url
  end

  test "logged in user can create a game" do
    log_in_as(@user)
    assert_difference('Game.count', 1) do
      post games_url(playerA: @user.id, playerB: @archer.id)
    end
    newGame = Game.last
    assert_redirected_to game_url(newGame)
    gameStateA = GameState.find(newGame.gameStateA)
    gameStateB = GameState.find(newGame.gameStateB)

    assert gameStateA.candidateWords.size == 17
    assert_match /\A\w{5}:\w{5}:\w{5}\z/, gameStateA.candidateWords
    assert_equal 0, gameStateA.wordIndex
    assert_equal 0, gameStateA.state

    assert gameStateB.candidateWords.size == 17
    assert_match /\A\w{5}:\w{5}:\w{5}\z/, gameStateB.candidateWords
    assert_equal 0, gameStateB.wordIndex
    assert_equal 0, gameStateB.state
  end

  test "non-logged-in-user can't see game" do
    get game_url(@game)
    assert_redirected_to login_url
  end

  test "logged-in-user can see game" do
    log_in_as(@user)
    get game_url(@game)
    assert_response :success
  end

  test "logged-in-user can't change an existing game" do
    log_in_as(@user)
    assert_raises do
      patch game_url(@game), params: {  }
    end
    # assert_redirected_to game_url(newGame)
  end

  test "non-logged-in-user can't destroy a game" do
    assert_difference('Game.count', 0) do
      delete game_url(@game)
    end
  end

  test "other logged-in-user can't destroy a game" do
    log_in_as(@user2)
    assert_difference('Game.count', 0) do
      delete game_url(@game)
    end
  end

  test "logged-in player can destroy a game" do
    log_in_as(@user)
    assert_difference('Game.count', -1) do
      delete game_url(@game)
    end
  end
end
