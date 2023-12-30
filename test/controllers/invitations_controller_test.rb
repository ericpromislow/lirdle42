require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user1)
    @other_user = users(:archer)
    @user101 = users(:user101)
    @user102 = users(:user102)
    @user103 = users(:user103)
    @invitation = Invitation.create(from: @user.id, to: @other_user.id)
  end
  test 'logged-in guy can create an invitation' do
    log_in_as(@user101)
    assert_difference('Invitation.count', 1) do
      post invitations_url(from: @user101.id, to: @user102.id)
    end
  end
  test "non-logged-in guy can't create an invitation" do
    assert_difference('Invitation.count', 0) do
      post invitations_url(from: @user.id, to: @other_user.id)
    end
  end
  test "other guy can't create a forged invitation" do
    log_in_as(@other_user)
    assert_difference('Invitation.count', 0) do
      post invitations_url(from: @user.id, to: @other_user.id)
    end
  end
  test "non-logged-in guy can't delete an invitation" do
    assert_difference('Invitation.count', 0) do
      delete invitation_url(@invitation, from: @user.id)
    end
  end
  test "other-logged-in guy can delete an invitation" do
    log_in_as(@other_user)
    assert_difference('Invitation.count', -1) do
      delete invitation_url(@invitation, from: @user.id)
    end
  end
  test "logged-in guy can delete an invitation" do
    log_in_as(@user)
    assert_difference('Invitation.count', -1) do
      delete invitation_url(@invitation, from: @user.id)
    end
  end

  test "need to be logged in to patch" do
    patch invitation_url(@invitation, originator: @user.id, reason: "bogus1")
    assert_redirected_to login_url
  end

  test "the originator can't be the sender" do
    log_in_as(@user)
    patch invitation_url(@invitation, originator: @user.id, reason: "bogus2")
    assert_response :bad_request
  end

  test "send-new-invite clears older invitations" do
    log_in_as(@user)
    inv2 = Invitation.create(from: @user.id, to: @other_user.id)
    inv3 = Invitation.create(from: @user.id, to: @other_user.id)
    post invitations_url(from: @user.id, to: @other_user.id)
    assert_equal 1, Invitation.where(from: @user.id).count
    assert_not_includes [@invitation.id, inv2.id, inv3.id], Invitation.where(from: @user.id).first.id
  end

  test "send-new-invite to x fails if x is processing another invite" do
    log_in_as(@user)
    fiveMinsOld = 5.minutes.ago
    @invitation.update_columns(created_at: fiveMinsOld, updated_at: fiveMinsOld)
    assert_difference('Invitation.where(to: @other_user.id).count', 0) do
      post invitations_url(from: @user.id, to: @other_user.id)
    end
    assert_equal 0, Invitation.where(id: @invitation.id).count
  end

  # This test is prob no longer applicable.
  # test "the originator needs to be the recipient" do
  #   log_in_as(@user)
  #   # @user.update_attribute(:admin, false)
  #   patch invitation_url(@invitation, originator: @other_user.id, reason: "bogus2")
  #   assert_response :ok
  # end
end
