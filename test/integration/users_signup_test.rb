require "test_helper"

class UsersSignupTest < ActionDispatch::IntegrationTest
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
    assert_select "a[href=?]", user_path(User.last)
  end

end
