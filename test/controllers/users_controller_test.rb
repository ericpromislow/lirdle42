require "test_helper"
require 'faker'

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user1)
    @other_user = users(:archer)
  end

  test "should redirect index-url when not logged in" do
    get users_url
    assert_redirected_to login_url
  end

  test "should redirect index-path when not logged in" do
    get users_path
    assert_redirected_to login_url
  end

  test "should get users list when logged in" do
    log_in_as(@user)
    get users_url
    assert_response :success
  end

  test "should get new" do
    get new_user_url
    assert_response :success
  end

  test "should not create duplicate user" do
    log_in_as(@user)
    assert_difference('User.count', 0) do
      post users_url, params: { user: { email: @user.email, is_temporary: @user.is_temporary, password: 'secret', password_confirmation: 'secret', profile_id: @user.profile_id, username: @user.username } }
    end
    assert_template 'new'
  end

  test "should create user" do
    username = Faker::Name.name
    email = Faker::Internet.email
    password = Faker::Internet.password
    assert_difference('User.count', 1) do
      post users_url, params: { user: { email: email, password: password, password_confirmation: password, profile_id: @user.profile_id, username: username } }
    end

    assert_redirected_to root_url
    newUser = User.last
    assert_equal username, newUser.username
    assert_equal email, newUser.email
    assert_equal false, newUser.admin
    assert_equal false, newUser.activated
    assert_equal ApplicationHelper::NUM_FREE_LOGINS - 1, newUser.inactive_logins
  end

  test "should show user" do
    get user_url(@user)
    assert_response :success
  end

  test "should get edit" do
    log_in_as(@user)
    get edit_user_url(@user)
    assert_response :success
  end

  test "should update user" do
    log_in_as(@user)
    patch user_url(@user), params: { user: { email: @user.email, is_temporary: @user.is_temporary, password: 'secret', password_confirmation: 'secret', profile_id: @user.profile_id, username: @user.username } }
    assert_redirected_to user_url(@user)
  end

  test "should require login to destroy a user" do
    assert_difference('User.count', 0) do
      delete user_url(@other_user)
    end
    assert_redirected_to login_url
  end

  test "should destroy user" do
    log_in_as(@user)
    assert_difference('User.count', -1) do
      delete user_url(@other_user)
    end
    assert_redirected_to users_url
  end

  test "should not destroy self" do
    log_in_as(@user)
    assert_difference('User.count', 0) do
      delete user_url(@user)
    end
    assert_redirected_to users_url
  end

  test "should not allow non-admin to destroy a user self" do
    log_in_as(@other_user)
    assert_difference('User.count', 0) do
      delete user_url(@user)
    end
    assert_redirected_to root_url
  end

  # Stuff that isn't just generated
  test "should set up a new user" do
    get signup_path
    assert_response :success
  end

  test "shouldn't allow a user to steal another user's username" do
    user2 = users(:user2)
    log_in_as(user2)
    patch user_url(user2), params: { user: { email: user2.email, username: @user.username } }
    assert_template 'edit'
  end

  test "should redirect edit when not logged in" do
    get edit_user_path(@user)
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test "should redirect edit when logged in as other user" do
    log_in_as(@other_user)
    get edit_user_path(@user)
    assert flash.empty?
    assert_redirected_to root_url
  end

  test "should redirect update when not logged in" do
    patch user_path(@user), params: { user: { name: @user.username,
      email: @user.email } }
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test "should redirect update when logged in as other user" do
    log_in_as(@other_user)
    patch user_path(@user), params: { user: { name: @user.username,
      email: @user.email } }
    assert flash.empty?
    assert_redirected_to root_url
  end

end
