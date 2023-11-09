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
  test "see the guess-words markup" do
    log_in_as(@user1)
    get game_path(@game)
    assert :success
    assert_template 'games/_show2'

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
  test "guess with empty params fails" do
    log_in_as(@user1)
    post guesses_path, params: {}
    assert_redirected_to root_url
    follow_redirect!
    assert_select 'div.alert-danger', "Invalid request: no game-state"
  end

  test "guess with bad game-state fails" do
    log_in_as(@user1)
    post guesses_path, params: {game_state_id: -1}
    assert_redirected_to root_url
    follow_redirect!
    assert_select 'div.alert-danger', "Invalid request: invalid game-state"
  end

  test "guess from wrong user fails" do
    log_in_as(@user1)
    post guesses_path, params: {game_state_id: @gs2.id }
    assert_redirected_to root_url
    follow_redirect!
    assert_select 'div.alert-danger', "Invalid request: unexpected user"
  end

  test "guess with no word fails" do
    log_in_as(@user1)
    post guesses_path, params: {game_state_id: @gs1.id }
    assert_template 'games/_show2'
    flash[:danger] = "Invalid request: no guess supplied"
  end

  test "guess with invalid word fails" do
    log_in_as(@user1)
    post guesses_path, params: {game_state_id: @gs1.id, word:"splibish" }
    assert_template 'games/_show2'
    flash[:danger] = "Not a valid word: splibish"
  end

  test "guess with duplicate word fails" do
    log_in_as(@user1)
    post guesses_path, params: {game_state_id: @gs1.id, word:"weedy" }
    # Move back to state-2
    @gs1.reload
    @gs1.update_attribute(:state, 2)
    post guesses_path, params: {game_state_id: @gs1.id, word:"weedy" }
    assert_template 'games/_show2'
    flash[:danger] = %Q/You already tried "splibish"/
  end

  test "guess with acceptable word moves to next template" do
    log_in_as(@user1)
    post guesses_path, params: {game_state_id: @gs1.id, word:"weedy" }
    assert_template 'games/_show3'
    # puts "QQQ: #{ response.body }"
    assert_select "p", "Waiting for #{ @user2.username } to finish guessing a word."
  end
end
