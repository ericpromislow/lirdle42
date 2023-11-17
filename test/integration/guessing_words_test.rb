require "test_helper"

class GuessingWordsTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:user1)
    @archer = users(:archer)
    @user2 = users(:user2)
    @game = games(:game1)
    @user1 = users(:user1)
    @user2 = users(:user2)
    @gs1 = @game.game_states.create(user: @user1, finalWord: "knell", candidateWords: "knell:molar:psalm", state: 2)
    @gs2 = @game.game_states.create(user: @user2, finalWord: "baton", candidateWords: "fetus:baton:frown", state: 2)
    # @gs1.save!
    # @gs2.save!
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
    assert_select 'div.alert-danger', "Invalid request: no guess supplied"
  end

  test "guess with invalid word fails" do
    log_in_as(@user1)
    w = "splibish"
    get is_valid_word_path(w)
    assert_equal false, JSON.parse(response.body)['status']
    post guesses_path, params: {game_state_id: @gs1.id, word:w }
    assert_template 'games/_show2'
    assert_select 'div.alert-danger', "Not a valid word: splibish"
  end

  test "guess with too-short word fails" do
    log_in_as(@user1)
    w = 'bake'
    get is_valid_word_path(w)
    assert_equal false, JSON.parse(response.body)['status']
    post guesses_path, params: {game_state_id: @gs1.id, word:w }
    assert_template 'games/_show2'
    assert_select 'div.alert-danger', "Not a valid word: bake"
  end

  test "guess with duplicate word fails" do
    log_in_as(@user1)
    w = 'weedy'
    get is_duplicate_guess_path(id: @gs1, word: w)
    assert_equal false, JSON.parse(response.body)['status']
    post guesses_path, params: {game_state_id: @gs1.id, word:w }
    # Move back to state-2
    @gs1.reload
    @gs1.update_attribute(:state, 2)
    get is_duplicate_guess_path(id: @gs1, word: w)
    assert_equal true, JSON.parse(response.body)['status']
    post guesses_path, params: {game_state_id: @gs1.id, word:w }
    assert_template 'games/_show2'
    assert_select 'div.alert-danger', %Q/You already tried "#{ w }"/
  end

  test "guess with acceptable word moves to next template" do
    log_in_as(@user1)
    post guesses_path, params: {game_state_id: @gs1.id, word:"weedy" }
    assert_redirected_to game_path(@game)
    follow_redirect!
    assert_template 'games/_show3'
    assert_select "p", "Waiting for #{ @user2.username } to finish guessing a word."
  end

  test "when both players have made a guess move to state 4" do
    log_in_as(@user1)
    post guesses_path, params: {game_state_id: @gs1.id, word:"paint" }
    assert_redirected_to game_path(@game)
    follow_redirect!
    assert_template 'games/_show3'
    log_in_as(@user2)
    post guesses_path, params: {game_state_id: @gs2.id, word:"lemon" }
    assert_redirected_to game_path(@game)
    follow_redirect!
    assert_template 'games/_show4'
    log_in_as(@user1)
    get game_path(@game)
    assert_template 'games/_show4'
    assert_select 'p', %Q/Target Word: knell/
    assert_select 'p', %Q/Their Current Guess: lemon/
    expected = [%w/l yellow/, %w/e yellow/, %w/m grey/, %w/o grey/, %w/n yellow/]
    i = 0
    assert_select 'div.letter-box.filled-box' do |elements|
      elt = elements[i]
      assert_includes elt.classes, "background-#{ expected[i][1] }"
      assert_includes elt.text, expected[i][0]
      i += 1
    end

    log_in_as(@user2)
    get game_path(@game)
    assert_template 'games/_show4'
    assert_select 'p', %Q/Target Word: baton/
    assert_select 'p', %Q/Their Current Guess: paint/
    expected = [%w/p grey/, %w/a green/, %w/i grey/, %w/n yellow/, %w/t yellow/]
    i = 0
    assert_select 'div.letter-box.filled-box' do |elements|
      elt = elements[i]
      assert_equal elt.text.strip, expected[i][0]
      assert_includes elt.classes, "background-#{ expected[i][1] }"
      i += 1
    end
  end

  test "when both players have picked a lie in state 4, they end up back in state 2" do
    log_in_as(@user1)
    post guesses_path, params: {game_state_id: @gs1.id, word:"paint" }
    assert_redirected_to game_path(@game)
    follow_redirect!
    assert_template 'games/_show3'
    log_in_as(@user2)
    post guesses_path, params: {game_state_id: @gs2.id, word:"lemon" }
    assert_redirected_to game_path(@game)
    follow_redirect!
    assert_template 'games/_show4'

    log_in_as(@user1)
    get game_path(@game)
    assert_template 'games/_show4'
    @gs2.reload
    patch game_state_path(@gs2, params: { lie: "1:1:2:green" })
    assert_redirected_to game_path(@game)
    follow_redirect!
    @gs1.reload
    @gs2.reload
    assert_equal 5, @gs1.state
    assert_equal 4, @gs2.state
    assert_template 'games/_show5'
    assert_select "p", "Waiting for #{ @user2.username } to finish picking a lie."

    log_in_as(@user2)
    get game_path(@game)
    assert_template 'games/_show4'
    @gs1.reload
    patch game_state_path(@gs1, params: { lie: "0:0:2:green" })
    assert_redirected_to game_path(@game)
    follow_redirect!
    @gs1.reload
    @gs2.reload
    assert_equal 2, @gs1.state
    assert_equal 2, @gs2.state
    assert_template 'games/_show2'
    expected = [%w/l yellow/, %w/e yellow/, %w/m grey/, %w/o grey/, %w/n yellow/]
    i = 0
    assert_select 'div#game-board div.letter-row-container[1] div.letter-row div.letter-box.filled-box' do |elements|
      elt = elements[i]
      assert_equal elt.text.strip, expected[i][0]
      assert_includes elt.classes, "background-#{ expected[i][1] }"
      i += 1
    end

    # puts "QQQ: #{ response.body }"

    log_in_as(@user1)
    get game_path(@game)
    assert_template 'games/_show2'
    # Target baton, guessed paint, lie: 0:0:2 ('p') should be green
    expected = [%w/p green/, %w/a green/, %w/i grey/, %w/n yellow/, %w/t yellow/]
    i = 0
    assert_select 'div.letter-box.filled-box', count: 5
    assert_select 'div.letter-box', count: 30
    assert_select 'div.letter-box.filled-box' do |elements|
      elt = elements[i]
      assert_equal elt.text.strip, expected[i][0]
      assert_includes elt.classes, "background-#{ expected[i][1] }"
      i += 1
    end
    assert_select 'div#keyboard-cont' do
      assert_select 'div.first-row button.keyboard-button', count: 10
      assert_select 'div.second-row button.keyboard-button', count: 9
      assert_select 'div.third-row button.keyboard-button', count: 9
    end

    log_in_as(@user2)
    get game_path(@game)
    assert_template 'games/_show2'
    # Target knell, guessed lemon, lie: 1:1:2 ('e') should be green
    expected = [%w/l yellow/, %w/e green/, %w/m grey/, %w/o grey/, %w/n yellow/]
    assert_select 'div.letter-box.filled-box', count: 5
    assert_select 'div.letter-box', count: 30
    i = 0
    assert_select 'div.letter-box.filled-box' do |elements|
      elt = elements[i]
      assert_equal elt.text.strip, expected[i][0]
      assert_includes elt.classes, "background-#{ expected[i][1] }"
      i += 1
    end
    assert_select 'div#keyboard-cont' do
      assert_select 'div.first-row button.keyboard-button', count: 10
      assert_select 'div.second-row button.keyboard-button', count: 9
      assert_select 'div.third-row button.keyboard-button', count: 9
    end
  end
end
