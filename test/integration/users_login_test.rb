require "test_helper"

class UsersLoginTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:user1)
  end
  test "login with invalid information" do
    get login_path
    assert_template "sessions/new"
    post login_path, params: { session: { email: @user.email, password: "barfy" }}
    assert_not is_logged_in?
    assert_template "sessions/new"
    assert_not flash.empty?
    get root_path
    assert flash.empty?
  end
  test "login with an actual user and then logout" do
    get login_path
    post login_path, params: { session: { email: @user.email, password: 'secret' }}
    assert is_logged_in?
    assert SessionsHelper.status.has_key?(@user.id)
    assert SessionsHelper.status[@user.id][:loggedIn]
    assert_nil SessionsHelper.status[@user.id][:gameID]
    assert_redirected_to  root_url
    follow_redirect!
    assert_template "static_pages/home"
    # puts "QQQ: #{ response.body }"
    assert_select "a[href=?]", signup_path, count: 0
    assert_select "a[href=?]", login_path, count: 0
    assert_select "a[href=?]", logout_path
    assert_select "a[href=?]", user_path(@user), count: 0

    delete logout_path
    assert_not is_logged_in?
    assert_redirected_to root_url
    follow_redirect!
    assert_template "static_pages/home"
    assert_select "a[href=?]", login_path
    assert_select "a[href=?]", logout_path, count: 0
    assert_select "a[href=?]", user_path(@user), count: 0

    # Simulate a user clicking logout in a second window
    delete logout_path
    follow_redirect!
    assert_select "a[href=?]", login_path
    assert_select "a[href=?]", logout_path, count: 0
    assert_select "a[href=?]", user_path(@user), count: 0
  end

  test "can log in with username" do
    # Can't do this because `session` isn't defined
    # assert !is_logged_in?
    get login_path
    post login_path, params: { session: { email: @user.username, password: "secret" }}
    assert is_logged_in?
  end

  test "can log in with username wrong case" do
    get login_path
    post login_path, params: { session: { email: @user.username.upcase, password: "secret" }}
    assert is_logged_in?
  end

  test "can log in with email wrong case" do
    get login_path
    post login_path, params: { session: { email: @user.email.upcase, password: "secret" }}
    assert is_logged_in?
  end

  test "login with remembering" do
    log_in_as(@user, remember_me: '1')
    assert_not_nil cookies['remember_token']
  end

  test "login without remembering" do
    log_in_as(@user, remember_me: '0')
    assert_nil cookies['remember_token']
  end

  test "admins see the users menu item" do
    assert @user.admin
    get login_path
    post login_path, params: { session: { email: @user.email, password: "secret" }}
    get root_path
    assert_template 'static_pages/home'
    assert_select "a[href=?]", users_path, count: 1
  end

  test "non-admins do not see the users menu item" do
    user = users(:user2)
    assert !user.admin
    get login_path
    post login_path, params: { session: { email: user.email, password: "secret" }}
    get root_path
    assert_template 'static_pages/home'
    assert_select "a[href=?]", users_path, count: 0
  end
end
