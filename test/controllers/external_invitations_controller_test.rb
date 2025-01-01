require "test_helper"

class ExternalInvitationsControllerTest < ActionDispatch::IntegrationTest
  def after_setup
    @user = users(:user1)
  end

  test "should get create" do
    log_in_as(@user)
    post external_invitations_url(id: @user.id)
    assert_nil flash[:danger]
    assert_not_nil flash[:info]
    assert_match(%r{Send them.*\w/join\?code=\d+_.*this link expires in 2 hours}, flash[:info])
    assert_redirected_to root_url
  end

  test "should fail when user isn't logged in" do
    post external_invitations_url(id: @user.id)
    assert_not flash.empty?
    assert_match("Please log in", flash[:danger])
    assert_redirected_to login_url
  end

  test "try creating an external invitation" do
    log_in_as(@user)
    post external_invitations_url(user: {id: @user.id})
    assert_redirected_to root_url
    follow_redirect!
    assert_not_nil flash[:info]
    puts "QQQ: flash: #{flash[:info]}"
    m = /join\?(.*?)'.*this link expires in (.*)/.match(flash[:info])
    assert_not_nil m
    assert_not_empty m[1]
    # flash[:info] =~ /join\?(.*?)'.*this link expires in (.*)/
    params = {id: m[1]}
    @user.reload
    puts "@user stuff: @user's invite_digest: #{@user.invite_digest}"
    puts "@user stuff: @user's invite_token: #{@user.invite_token}"
    puts "@user stuff: @user's invite_sent_at: #{ @user.invite_sent_at }"
    puts "QQQ: params: #{params}"
    # urlParams = "#{@user.id}_#{@user.invite_digest}"
    # url = "#{root_url}join?#{urlParams}"
    get edit_external_invitation_url(params)
    assert_redirected_to root_url
    follow_redirect!
    assert_empty flash
  end
  # test "should get update" do
  #   get external_invitations_update_url
  #   assert_response :success
  # end
  #
  # test "should get delete" do
  #   get external_invitations_delete_url
  #   assert_response :success
  # end
end
