require "test_helper"

class UsersSignupTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
  end

  test "invalid info doesn't create a user" do
    get signup_path
    assert_no_difference 'User.count' do
      post users_path, params: { user: { username: '',
          email: 'u@i',
          password: 'abc',
          password_confirmation: 'defghi'
        }
      }
    end
    assert_template 'users/new'
    assert_select 'div#error_explanation .alert', 'The form contains 4 errors.'
    assert_select 'div#error_explanation ul li[1]', "Username can't be blank"
    assert_select 'div#error_explanation ul li[2]', "Email is invalid"
    assert_select 'div#error_explanation ul li[4]', "Password is too short (minimum is 4 characters)"
    assert_select 'div#error_explanation ul li[3]', "Password confirmation doesn't match Password"
  end

  test "valid user info adds the user" do
    get signup_path
    assert_difference 'User.count', 1 do
      post users_path, params: { user: {
        username: 'charlie1',
        email: 'charlie1u@i.com',
        password: 'charlie1',
        password_confirmation: 'charlie1'
      }
      }
    end
    follow_redirect!
    assert_template 'static_pages/home'
    assert is_logged_in?
    # puts "QQQ: #{ response.body }"
    assert_select 'div.alert-success', 'Welcome, charlie1'
    assert_select "a[href=?]", signup_path, count: 0
    assert_select "a[href=?]", login_path, count: 0
    assert_select "a[href=?]", logout_path
    assert_select "a[href=?]", user_path(User.last), count: 0
    user = User.last
    assert_equal 9, user.inactive_logins
    assert !user.activated
  end

  test "valid signup info with account activation" do
    get signup_path
    assert_difference 'User.count', 1 do
      post users_path, params: { user: {
        username: 'charlie2',
        email: 'charlie2u@i.com',
        password: 'secret',
        password_confirmation: 'secret'
      }
    }
    end
    user = assigns(:user)
    # puts "User name: #{ user.username }"
    # puts "Token after creating user should be empty: #{user.activation_token}"
    post account_activations_path, params: { user: { id: user.id } }
    user = assigns(:user)
    # puts "Token after creating account-activation should be non-empty: #{user.activation_token}"
    assert_redirected_to root_url
    follow_redirect!
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not user.activated?
    # puts "QQQ: #{ response.body }"
    assert_select 'div.alert-info', /Please check your email/
    # Note that in this app the user is logged in, but not activated

    # Invalid activation token
    get edit_account_activation_path(user.id, token: "invalid token", email: user.email)
    assert_redirected_to root_url
    follow_redirect!
    assert_not user.reload.activated?
    assert_select 'div.alert-danger', /Invalid activation link/

    # Valid token, wrong email
    get edit_account_activation_path(user.id, token: user.activation_token, email: 'wrong')
    assert_redirected_to root_url
    follow_redirect!
    assert_not user.reload.activated?
    assert_select 'div.alert-danger', /Can't find a user with email "wrong"/

    # Valid activation token
    get edit_account_activation_path(user.id, token: user.activation_token, email: user.email)
    assert_redirected_to root_url
    follow_redirect!
    assert user.reload.activated?
    assert_select 'div.alert-success', /Account activated/

    # Already activated
    get edit_account_activation_path(user.id, token: user.activation_token, email: user.email)
    assert_redirected_to root_url
    follow_redirect!
    assert user.reload.activated?
    assert_select 'div.alert-danger', /User charlie2 is already activated/
  end

end
