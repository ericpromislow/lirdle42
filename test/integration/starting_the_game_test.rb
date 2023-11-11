require "test_helper"

class StartingTheGameTest < ActionDispatch::IntegrationTest
  def setup
    @user1 = users(:user1)
    @user2 = users(:user2)
  end
  test "create and start playing the game" do
    log_in_as(@user1)
    post games_path, params: { playerA: @user1.id, playerB: @user2.id}
    assert :success
    newGame = Game.last
    gs1 = GameState.find(newGame.gameStateA)
    gs2 = GameState.find(newGame.gameStateB)
    gs1.update_attribute(:candidateWords, "knell:molar:psalm")
    gs2.update_attribute(:candidateWords, "fetus:baton:frown")
    get game_path(newGame)
    assert_template 'games/_show0'
    # puts "QQQ: #{ response.body }"
    assert_select "a[href=?]",  root_path
    assert_select "a[href=?]",  help_path
    assert_select "a[href=?]",  about_path
    assert_select "a[href=?]",  contact_path
    assert_select "span", "Logged in as #{ @user1.username }"
    assert_select "p", /You can choose/
    assert_select "p strong", "knell"
    assert_select "p", /Or you can take a chance on the next 2 words/
    assert_select "input[type=submit]" do |btn|
      assert_match /"knell" sounds good/, btn.attribute('value').value
    end
    assert_select "input[type=submit][value=?]", 'Try the next word'
    # Simulate clicking on the next word
    gs1.reload
    patch game_state_path(gs1, { wordIndex: gs1.wordIndex + 1 })
    assert_redirected_to game_path(newGame)
    follow_redirect!
    assert_template 'games/_show0'
    assert_select "p", /You can choose/
    assert_select "p strong", "molar"
    assert_select "p", /Or you can go with the last word in the list/
    assert_select "input[type=submit]" do |btn|
      assert_equal 'Settle for "molar"', btn.attribute('value').value
    end
    assert_select "input[type=submit][value=?]", "Let's take a chance on door #3"


    # Simulate clicking on door #3
    gs1.reload
    patch game_state_path(gs1, { wordIndex: gs1.wordIndex + 1 })
    assert_redirected_to game_path(newGame)
    follow_redirect!
    assert_template 'games/_show0'
    assert_select "h2", /Your opponent's word is/
    assert_select "h2 strong", "psalm"
    assert_select "p", /Press the 'OK' button to continue/
    assert_select "p", { text: %r{you can go with the last word in the list}, count: 0 }

    assert_select "input[type=submit]" do |btn|
      assert_equal 'OK', btn.attribute('value').value
    end

    # Click the OK button
    patch game_state_path(gs1, { finalWord: "psalm" })
    assert_redirected_to game_path(newGame)
    follow_redirect!
    assert_template 'games/_show1'
    assert_select "h2", /#{ @user2.username }'s word is/
    assert_select "h2 strong", "psalm"
    assert_select "p", "Waiting for #{ @user2.username } to pick your word"
  end

  test "move to state 2 when both players are ready" do
    log_in_as(@user1)
    post games_path, params: { playerA: @user1.id, playerB: @user2.id}
    newGame = Game.last
    gs1 = GameState.find(newGame.gameStateA)
    gs2 = GameState.find(newGame.gameStateB)
    gs1.update_attribute(:candidateWords, "knell:molar:psalm")
    gs2.update_attribute(:candidateWords, "fetus:baton:frown")
    patch game_state_path(gs1, { finalWord: 'molar' })
    assert_redirected_to game_path(newGame)
    follow_redirect!
    assert_template 'games/_show1'

    log_in_as(@user2)
    get game_path(newGame)
    # puts "QQQ: #{ response.body }"
    # # fetus:baton:frown
    assert_select "span", "Logged in as #{ @user2.username }"
    assert_select "p", /You can choose/
    assert_select "p strong", "fetus"
    assert_select "p", /Or you can take a chance on the next 2 words/
    assert_select "input[type=submit]" do |btn|
      assert_match /"fetus" sounds good/, btn.attribute('value').value
    end
    assert_select "input[type=submit][value=?]", 'Try the next word'
    # Simulate clicking on the next word
    gs2.reload
    patch game_state_path(gs2, { wordIndex: gs2.wordIndex + 1 })
    assert_redirected_to game_path(newGame)
    follow_redirect!
    assert_template 'games/_show0'
    assert_select "p", /You can choose/
    assert_select "p strong", "baton"
    assert_select "p", /Or you can go with the last word in the list/
    assert_select "input[type=submit]" do |btn|
      assert_equal 'Settle for "baton"', btn.attribute('value').value
    end
    assert_select "input[type=submit][value=?]", "Let's take a chance on door #3"

    # Simulate clicking on door #3
    gs2.reload
    patch game_state_path(gs2, { wordIndex: gs2.wordIndex + 1 })
    assert_redirected_to game_path(newGame)
    follow_redirect!
    assert_template 'games/_show0'
    assert_select "h2", /Your opponent's word is/
    assert_select "h2 strong", "frown"
    assert_select "p", /Press the 'OK' button to continue/
    assert_select "p", { text: %r{you can go with the last word in the list}, count: 0 }

    assert_select "input[type=submit]" do |btn|
      assert_equal 'OK', btn.attribute('value').value
    end

    # Click the OK button
    patch game_state_path(gs2, { finalWord: "psalm" })
    assert_redirected_to game_path(newGame)
    follow_redirect!
    assert_template 'games/_show2'
    # assert_select "h2", /#{ @user1.username }'s word is/
    # assert_select "h2 strong", "psalm"
    # assert_select "p", "Waiting for #{ @user1.username } to pick your word"

    # Simulate player 1 regetting the game
    log_in_as(@user1)
    get game_path(newGame)
    assert :success
    assert_template 'games/_show2'
  end
end
