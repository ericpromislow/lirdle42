require "test_helper"

class UsersEditTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:user1)
  end

  test "unsuccessful edit" do
    log_in_as(@user)
    get edit_user_path(@user)
    assert_template 'users/edit'
    patch user_path(@user), params: {
      user: {
        username: "",
        email: "joe", # email is ignored
        password: "splibitch",
        password_confirmation: "splibitch_x",
      }
    }
    assert_template 'users/edit'
    assert_select 'div#error_explanation .alert', 'The form contains 2 errors.'
    assert_select 'div#error_explanation ul li[1]', "Username can't be blank"
    assert_select 'div#error_explanation ul li[2]', "Password confirmation doesn't match Password"
  end

  test "unsuccessful edit: can't steal another user's username" do
    user2 = users(:user2)
    log_in_as(user2)
    get edit_user_path(user2)
    patch user_path(user2), params: {
      user: {
        username: @user.username,
        email: user2.email,
      }
    }
    assert_template 'users/edit'
    assert_select 'div#error_explanation .alert', 'The form contains 1 error.'
    assert_select 'div#error_explanation ul li[1]', "Username has already been taken"

      # assert_select 'div.row aside section.user_info h1', @user.username
  end

  test "successful edit" do
    log_in_as(@user)
    get edit_user_path(@user)
    name = "new-joe"
    patch user_path(@user), params: {
      user: {
        username: name,
        email: @user.email,
      }
    }
    assert_redirected_to @user
    follow_redirect!
    assert_not flash.empty?
    @user.reload
    assert_equal name, @user.username
  end

  test "fails when not logged in" do
    delete logout_path
    assert_redirected_to root_url
    follow_redirect!
    get edit_user_path(@user)
    name = "carl"
    patch user_path(@user), params: {
      user: {
        username: name,
        email: @user.email,
      }
    }
    assert_redirected_to login_url
    follow_redirect!
    assert_not flash.empty?
  end

  test 'login after page-visit attempt redirects to the destination' do
    get edit_user_path(@user)
    assert_redirected_to login_url
    follow_redirect!
    log_in_as(@user)
    assert_redirected_to edit_user_path(@user)
    follow_redirect!
    username = "chuck"
    patch user_path(@user), params: { user: { username: username } }

    assert_not flash.empty?
    assert_redirected_to @user
    follow_redirect!
    @user.reload
    assert_equal username, @user.username

    delete logout_path
    assert_nil session[:forwarding_url]
    get root_path
    log_in_as(@user)
    assert_redirected_to root_url
  end

  test "non-admin user can't make themselves admin" do
    @other_user = users(:archer)
    assert_equal false, @other_user.admin
    log_in_as(@other_user)
    patch user_path(@other_user), params: { user: {admin: true }}
    assert_redirected_to @other_user
    follow_redirect!
    assert_not flash.empty?
    @other_user.reload
    assert_equal false, @other_user.admin
  end
end
