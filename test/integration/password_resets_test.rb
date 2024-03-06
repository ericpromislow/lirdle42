require "test_helper"

class PasswordResetsTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:user1)
  end

  test "password resets" do
    get new_password_reset_path
    assert_template "password_resets/new"
    assert_select "input[name=?]", "password_reset[email]"

    # Invalid email
    post password_resets_path, params: { password_reset: { email: "" }}
    assert_not flash.empty?
    assert_template "password_resets/new"

    # Valid email
    post password_resets_path, params: { password_reset: { email: @user.email }}
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not flash.empty?
    assert_redirected_to root_url

    # Password reset form
    user = assigns(:user)

    # Wrong email
    get edit_password_reset_path(user.reset_token, email: 'bad')
    assert_not flash.empty?
    assert_redirected_to root_url
    follow_redirect!
    assert_select 'div.alert-danger', "Email address bad not found"

    # Inactive user
    user.toggle!(:activated)
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_not flash.empty?
    assert_redirected_to root_url
    follow_redirect!
    assert_select 'div.alert-danger', "User #{user.email} isn't activated yet"
    user.toggle!(:activated)

    # Right email, bad token
    get edit_password_reset_path(user.reset_token + "blab", email: user.email)
    assert_redirected_to root_url
    follow_redirect!
    assert_not flash.empty?
    assert_select 'div.alert-danger', "Invalid password-reset link for user #{ user.username }. Where'd you get this from?"

    # Right email, right token
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_template "password_resets/edit"
    assert_select "input[name=email][type=hidden][value=?]", user.email

    # Invalid password & confirmation
    patch(password_reset_path(user.reset_token),
      params: { email: user.email,
        user: { password: 'precious', password_confirmation: "special" }})
    assert_select 'div#error_explanation .alert', 'The form contains 1 error.'
    assert_select 'div#error_explanation ul li[1]', "Password confirmation doesn't match Password"
    assert_select "input[name=email][type=hidden][value=?]", user.email
    assert_template "password_resets/edit"

    # Empty password
    patch(password_reset_path(user.reset_token),
      params: { email: user.email,
        user: { password: '', password_confirmation: "" }})
    assert_select 'div#error_explanation .alert', 'The form contains 1 error.'
    assert_select 'div#error_explanation ul li[1]', "Password can't be empty"
    assert_select "input[name=email][type=hidden][value=?]", user.email

    # Valid password & confirmation
    patch(password_reset_path(user.reset_token),
      params: { email: user.email,
        user: { password: 'precious', password_confirmation: "precious" }})
    assert is_logged_in?
    assert_not flash.empty?
    assert_redirected_to root_url
    follow_redirect!
    assert_select 'div.alert-success', "Password for #{user.username} has been reset."
  end

  test 'expired token is rejected' do
    get new_password_reset_path
    post password_resets_path, params: { password_reset: { email: @user.email }}

    @user = assigns(:user)
    @user.update_attribute(:reset_sent_at, 3.hours.ago)
    patch(password_reset_path(@user.reset_token),
      params: { email: @user.email,
            token: @user.reset_token,
            user: { password: 'precious', password_confirmation: "precious" }})
    assert_redirected_to new_password_reset_url
    assert_not flash.empty?
    follow_redirect!
    # assert_match /expired/i, response.body
    assert_select 'div.alert-danger', /Password reset has expired/
  end

end
