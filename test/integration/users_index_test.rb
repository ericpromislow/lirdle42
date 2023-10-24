require "test_helper"

class UsersIndexTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:user1)
    @non_admin = users(:archer)
  end

  test "index including pagination and deleting" do
    log_in_as(@user)
    get users_path
    assert_template 'users/index'
    assert_select 'div.pagination'
    i = 0
    User.order('LOWER(username)').paginate(page: 1, per_page: 10).each do |user|
      assert_select 'a[href=?]', user_path(user), text: user.username
      if user != @user
        assert_select "a[href=?]", user_path(user), text: 'delete'
      end
      i += 1
    end
    assert_difference 'User.count', -1 do
      delete user_path(@non_admin)
    end
    # Make sure we did all those selects
    assert_equal 10, i
  end

  test "index as non-admin" do
    log_in_as(@non_admin)
    get users_path
    assert_template 'users/index'
    assert_select 'div.pagination'
    assert_select 'a', text:'delete', count: 0
  end

end
