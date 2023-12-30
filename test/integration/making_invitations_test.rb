require "test_helper"

class MakingInvitationsTest < ActionDispatch::IntegrationTest
  def setup
    @user1 = users(:user1)
    @user2 = users(:user2)
    @user1.update_attribute(:waiting_for_game, true)
    @user2.update_attribute(:waiting_for_game, true)
  end
  test "If A->B, then B->A fails" do
    log_in_as(@user1)
    get root_url
    post invitations_path, params: { from: @user1.id, to: @user2.id }
    assert :success
    delete logout_path
    log_in_as(@user2)
    post invitations_path, params: { from: @user2.id, to: @user1.id }
    assert_redirected_to root_url
    follow_redirect!
    assert_template "static_pages/home"
    assert_not flash.empty?
    # puts "QQQ: #{ response.body }"
    assert_select 'div.alert-danger', "user2 is currently considering an invitation from someone else."
  end

  test "If A->B, then B->C fails" do
    @user3 = users(:archer)
    @user3.update_attribute(:waiting_for_game, true)
    log_in_as(@user1)
    get root_url
    post invitations_path, params: { from: @user1.id, to: @user2.id }
    assert :success
    delete logout_path
    log_in_as(@user2)
    post invitations_path, params: { from: @user2.id, to: @user3.id }
    assert_redirected_to root_url
    follow_redirect!
    assert_template "static_pages/home"
    assert_not flash.empty?
    assert_select 'div.alert-danger', "user2 is currently considering an invitation from someone else."
  end
end
