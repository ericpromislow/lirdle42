class AddInactiveLoginCountToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :inactive_logins, :integer, default: 0
  end
end
