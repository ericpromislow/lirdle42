require "test_helper"

class GuessingWordsTest < ActionDispatch::IntegrationTest
  def setup
    @user1 = users(:user1)
    @user2 = users(:user2)
    @game = Game.create
    @gs1 = GameState.create(game: @game, playerID: @user1.id, finalWord: "knell", state: 2)
    @gs2 = GameState.create(game: @game, playerID: @user2.id, finalWord: "baton", state: 2)
    @game.update_columns(gameStateA: @gs1.id, gameStateB: @gs2.id)
  end
  test "guess words" do
    log_in_as(@user1)
    get game_path(@game)
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
