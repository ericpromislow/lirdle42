require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "account_activation" do
    user = users(:user1)
    user.activation_token = User.new_token
    mail = UserMailer.account_activation(user)
    assert_equal "#{ ApplicationHelper::APPNAME.capitalize } account activation", mail.subject
    assert_equal [user.email], mail.to
    assert_equal ["appname+no-reply@#{ ApplicationHelper::APPNAME }.com"], mail.from
    assert_match "Hello,", mail.body.encoded
    assert_match user.username, mail.body.encoded
    assert_match CGI.escape(user.email), mail.body.encoded
  end

  test "password_reset" do
    user = users(:user1)
    user.reset_token = User.new_token
    mail = UserMailer.password_reset(user)
    assert_equal "#{ ApplicationHelper::APPNAME.capitalize } password reset", mail.subject
    assert_equal [user.email], mail.to
    assert_equal ["appname+no-reply@#{ ApplicationHelper::APPNAME }.com"], mail.from
    assert_match "Hello,", mail.body.encoded
  end

end
