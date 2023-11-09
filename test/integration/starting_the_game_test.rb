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
    puts "QQQ: #{ response.body }"
    assert_select "a[href=?]",  root_path
    assert_select "a[href=?]",  help_path
    assert_select "a[href=?]",  about_path
    assert_select "a[href=?]",  contact_path
    assert_select "span", "Logged in as #{ @user1.username }"
    assert_select "p", "Do you want to go with \"knell\"? There are two words left to choose from."
    assert_select "button", "Yes"
    assert_select "button", "No"
  end
end
