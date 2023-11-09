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
    gameStateA = GameState.find(newGame.gameStateA)
    patch game_state_path(gameStateA, { wordIndex: gameStateA.wordIndex + 1 })
    assert_template 'games/_show0'
    assert_select "p", /You can choose/
    assert_select "p strong", "molar"
    assert_select "p", /Or you can go with the last word in the list/
    assert_select "input[type=submit]" do |btn|
      assert_equal 'Settle for "molar"', btn.attribute('value').value
    end
    assert_select "input[type=submit][value=?]", "Let's take a chance on door #3"


    # Simulate clicking on door #3
    gameStateA = GameState.find(newGame.gameStateA)
    patch game_state_path(gameStateA, { wordIndex: gameStateA.wordIndex + 1 })
    assert_template 'games/_show0'
    assert_select "h2", /Your opponent's word is/
    assert_select "h2 strong", "psalm"
    assert_select "p", /Press the 'OK' button to continue/
    assert_select "p", { text: %r{you can go with the last word in the list}, count: 0 }

    assert_select "input[type=submit]" do |btn|
      assert_equal 'OK', btn.attribute('value').value
    end

    # Click the OK button
    patch game_state_path(gameStateA, { finalWord: "psalm" })
    assert_template 'games/_show1'
    assert_select "h2", /#{ @user2.username }'s word is/
    assert_select "h2 strong", "psalm"
    assert_select "p", "Waiting for #{ @user2.username } to pick your word"
  end
  # TODO: Write a test where @user1 has moved to state1 and now @user2 is moving from state0 to 1.
  # @user2 should assert_template 'games/_show2'
  # and @user1 needs to get a message telling them to regrab game_path(@game)
end
