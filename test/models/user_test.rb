require "test_helper"
require 'faker'

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(username: "Example User", email: "user@example.com",
      password: "foobar", password_confirmation: "foobar")
  end

  test "basic is valid" do
    assert @user.valid?
  end

  test "longer password is valid" do
    # Don't know where 72 comes from (yet)
    @user.password_confirmation = @user.password = 'x' * 72
    assert @user.valid?
  end

  test "space not good" do
    @user.username = '     ';
    assert_not @user.valid?
    assert_includes @user.errors.full_messages, "Username can't be blank"
  end

  test "needs password matching" do
    @user.password_confirmation += ' '
    assert_not @user.valid?
  end

  test "password too short" do
    @user.password_confirmation = @user.password = '123'
    assert_not @user.valid?
    assert_includes @user.errors.full_messages, "Password is too short (minimum is 4 characters)"
  end

  test "password too long" do
    @user.password_confirmation = @user.password = 'x' * 73
    assert_not @user.valid?
    assert_includes @user.errors.full_messages, "Password is too long (maximum is 72 characters)"
  end

  test "password can be all-white-space" do
    @user.password = @user.password_confirmation = " " * 12
    assert @user.valid?
    @user.password = @user.password_confirmation = " \t\r\n" * 12
    assert @user.valid?
  end

  test "missing name" do
    u = User.new(username: "", email: "user@example.com",
      password: "foobar", password_confirmation: "foobar")
    assert_not u.valid?
  end

  test "bad email" do
    u = User.new(username: "fsda", email: "horkye",
      password: "foobar", password_confirmation: "foobar")
    assert_not u.valid?
    end

  test "email validation should reject invalid addresses" do
    invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.
                           foo@.com @bar+baz.com]
    invalid_addresses.each do |invalid_address|
      @user.email = invalid_address
      assert_not @user.valid?, "#{invalid_address.inspect} should be invalid"
    end
  end


  test "email too long" do
    @user.email = 'x' * 150 + '@cheeps.com'
    assert_not  @user.valid?
    assert_includes @user.errors.full_messages, "Email is too long (maximum is 150 characters)"
  end

  test "email in use" do
    user1 = User.all[0]
    username = Faker::Name.name
    password = Faker::Internet.password
    user = User.new(username: username, email: user1.email, password: password, password_confirmation: password)
    user.save
    assert_not  user.valid?
    assert_includes user.errors.full_messages, "Email has already been taken"
  end

  test "username in use" do
    user1 = User.all[0]
    email = Faker::Internet.email
    password = Faker::Internet.password
    user2 = User.new(username: user1.username, email: email, password: password, password_confirmation: password)
    assert_not user2.valid?
    assert_includes user2.errors.full_messages, "Username has already been taken"
  end

  test "email addresses should be saved as lowercase" do
    mixed_case_email = "Foo@ExAMPle.CoM"
    @user.email = mixed_case_email
    @user.save
    assert_equal mixed_case_email.downcase, @user.reload.email
  end

  test "upper-case email in use" do
    user1 = User.all[0]
    username = Faker::Name.name
    password = Faker::Internet.password
    user = User.new(username: username, email: user1.email.upcase, password: password, password_confirmation: password)
    user.save
    assert_not  user.valid?
    assert_includes user.errors.full_messages, "Email has already been taken"
  end

  test "authenticated? should return false for a user with nil digest" do
    assert_not @user.authenticated?(nil)
  end

end
