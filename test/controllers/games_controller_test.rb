require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:user1)
    @archer = users(:archer)
    @user2 = users(:user2)
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
      post games_url, params: { game: { playerA: @user.id, playerB: @archer.id} }
    end
    assert_redirected_to login_url
  end

  test "logged in non-admin user can't create a game for others" do
    log_in_as(@user2)
    assert_difference('Game.count', 0) do
      post games_url, params: { game: { playerA: @user.id, playerB: @archer.id} }
    end
    assert_redirected_to root_url
  end

  test "logged in user can create a game" do
    log_in_as(@user)
    assert_difference('Game.count', 1) do
      post games_url, params: { game: { playerA: @user.id, playerB: @archer.id} }
    end
    newGame = Game.last
    assert_redirected_to game_url(newGame)
    assert newGame.candidateWordsForA.size == 17
    assert newGame.candidateWordsForB.size == 17
    assert_match /\A\w{5}:\w{5}:\w{5}\z/, newGame.candidateWordsForA
    assert_match /\A\w{5}:\w{5}:\w{5}\z/, newGame.candidateWordsForB
    assert_equal 0, newGame.wordIndexForA
    assert_equal 0, newGame.wordIndexForB
  end

  test "non-logged-in-user can't see game" do
    game1 = games(:one)
    get game_url(game1)
    assert_redirected_to login_url
  end

  test "logged-in-user can see game" do
    log_in_as(@user)
    game1 = games(:one)
    get game_url(game1)
    assert_response :success
  end

  test "non-logged-in-user can't update game" do
    game1 = games(:one)
    patch game_url(game1), params: { game: { playerA: game1.playerA, playerB: game1.playerB, stateA: 1 } }
    assert_redirected_to login_url
  end

  test "logged-in-user can't change a player of an existing game" do
    log_in_as(@user)
    assert_difference('Game.count', 1) do
      post games_url, params: { game: { playerA: @user.id, playerB: @archer.id} }
    end
    newGame = Game.last
    patch game_url(newGame), params: { game: { playerA: @user2.id} }
    assert_redirected_to game_url(newGame)
    newGame.reload
    assert_equal newGame.playerA, @user.id
  end

  test "logged-in-user can change other fields an existing game" do
    log_in_as(@user)
    assert_difference('Game.count', 1) do
      post games_url, params: { game: { playerA: @user.id, playerB: @archer.id} }
    end
    newGame = Game.last
    patch game_url(newGame), params: { game: { stateA: 1, stateB: 2, candidateWordsForA: "blame:dandy:steel", candidateWordsForB: "scare:coupe:scold", wordIndexForA: 1, wordIndexForB: 2, finalWordForA: "blame", finalWordForB: "coupe" } }
    assert_redirected_to game_url(newGame)
    newGame.reload
    assert_equal 1, newGame.stateA
    assert_equal 2, newGame.stateB
    assert_equal "blame:dandy:steel", newGame.candidateWordsForA
    assert_equal "scare:coupe:scold", newGame.candidateWordsForB
    assert_equal 1, newGame.wordIndexForA
    assert_equal 2, newGame.wordIndexForB
    assert_equal "blame", newGame.finalWordForA
    assert_equal "coupe", newGame.finalWordForB
  end

  test "non-logged-in-user can't destroy a game" do
    game1 = games(:one)
    assert_difference('Game.count', 0) do
      delete game_url(game1)
    end
  end

  test "other logged-in-user can't destroy a game" do
    log_in_as(@user)
    assert_difference('Game.count', 1) do
      post games_url, params: { game: { playerA: @user.id, playerB: @archer.id} }
    end
    newGame = Game.last
    log_in_as(@user2)
    assert_difference('Game.count', 0) do
      delete game_url(newGame)
    end
  end

  test "logged-in player can destroy a game" do
    log_in_as(@user)
    assert_difference('Game.count', 1) do
      post games_url, params: { game: { playerA: @user.id, playerB: @archer.id} }
    end
    newGame = Game.last
    assert_difference('Game.count', -1) do
      delete game_url(newGame)
    end
  end

  # test "logged-in-user can see game" do
  #   log_in_as(@user)
  #   game1 = games(:one)
  #   get game_url(game1)
  #   assert_response :success
  # end
end
