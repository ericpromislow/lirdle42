require "test_helper"

class GuessingWordsTest < ActionDispatch::IntegrationTest
  def setup
    @user1 = users(:user1)
    @user2 = users(:user2)
  end
  test "guess words" do
    log_in_as(@user1)
    post games_path, params: { playerA: @user1.id, playerB: @user2.id}
    assert :success
    newGame = Game.last
    get game_path(newGame)
    newGame = Game.last
    gameStateA = GameState.find(newGame.gameStateA)
    patch game_state_path(gameStateA, { finalWord: 'molar' })
    assert :success
    assert_template 'games/_show1'

    log_in_as(@user2)
    gameStateB = GameState.find(newGame.gameStateB)
    patch game_state_path(gameStateB, { finalWord: "psalm" })
    assert_template 'games/_show2'
    # get game_path(newGame)
    log_in_as(@user1)
    get game_path(newGame)
    assert :success
    assert_template 'games/_show2'
    # puts "QQQ: #{ response.body }"

    assert_select 'div#game-board' do
      assert_select 'div.letter-row-container', count: 6
      assert_select 'div.letter-row-container div.letter-row div.letter-box', { text: '', count: 30 }
    end
    assert_select 'div#keyboard-cont' do
      assert_select 'div.first-row button.keyboard-button', count: 10
      assert_select 'div.second-row button.keyboard-button', count: 9
      assert_select 'div.third-row button.keyboard-button', count: 9
    end
  end
end
