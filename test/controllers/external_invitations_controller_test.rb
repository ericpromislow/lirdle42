require "test_helper"

class ExternalInvitationsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get external_invitations_create_url
    assert_response :success
  end

  test "should get update" do
    get external_invitations_update_url
    assert_response :success
  end

  test "should get delete" do
    get external_invitations_delete_url
    assert_response :success
  end
end
