require "test_helper"

class UsersWaitingTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:user1)
  end

  test "user must be logged in" do
    # assert !is_logged_in?
    patch user_path(@user), params: {
      user: {
        waiting_for_game: true,
      }
    }
    assert !is_logged_in?
    assert_redirected_to  login_url
    follow_redirect!
    assert_template "sessions/new"
    assert_not flash.empty?
    # puts "QQQ: #{ response.body }"
    assert_select 'div.alert-danger', "Please log in"
  end

  test "admin can put another user on the waiting list" do
    log_in_as(@user)
    user2 = users(:user2)
    patch user_path(user2), params: {
      user: {
        waiting_for_game: true,
      }
    }
    assert_redirected_to root_url
    follow_redirect!
    assert_template "static_pages/home"
    # puts "QQQ: #{ response.body }"
    assert flash.empty?
  end

  test "non-admin can't put another user on the waiting list" do
    user2 = users(:user2)
    log_in_as(user2)
    patch user_path(@user), params: {
      user: {
        waiting_for_game: true,
      }
    }
    assert_redirected_to root_url
    follow_redirect!
    assert_template "static_pages/home"
    assert_not flash.empty?
    assert_select 'div.alert-danger', "You can't update user #{ @user.username }"
  end

  test "successfully add to and from waiting  list" do
    log_in_as(@user)
    patch user_path(@user), params: {
      user: {
        waiting_for_game: true,
      }
    }
    assert_redirected_to root_url
    follow_redirect!
    assert_template "static_pages/home"
    # puts "QQQ: #{ response.body }"
    assert_select 'li', @user.username

    patch user_path(@user), params: {
      user: {
        waiting_for_game: false,
      }
    }
    assert_redirected_to root_url
    follow_redirect!
    assert_template "static_pages/home"
    # puts "QQQ: #{ response.body }"
    # ### TODO: Verify @user.username isn't on the waiting list
    assert_select 'li', { text: @user.username, count: 0 }
    @user.reload
    assert !@user.waiting_for_game
  end

  test "when the other guy leaves his name isn't on the board" do
    log_in_as(@user)
    patch user_path(@user), params: {
      user: {
        waiting_for_game: true,
      }
    }
    assert_redirected_to root_url
    follow_redirect!
    assert_template "static_pages/home"
    # puts "QQQ: #{ response.body }"
    assert_select 'li', @user.username

    user2 = users(:user2)
    log_in_as(user2)
    patch user_path(user2), params: {
      user: {
        waiting_for_game: true,
      }
    }
    assert_redirected_to root_url
    follow_redirect!
    assert_template "static_pages/home"
    assert flash.empty?
    assert_select 'ul.list-group li', @user.username
    assert_select 'ul.list-group li', user2.username

    log_in_as(@user)
    delete logout_path
    assert_not is_logged_in?
    assert_redirected_to root_url
    follow_redirect!
    assert_template "static_pages/home"
    assert_select 'p', 'Currently 1 person is waiting to play'
  end

end
