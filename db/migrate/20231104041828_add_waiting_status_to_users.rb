class AddWaitingStatusToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :waiting_for_game, :boolean, default: false
    add_index :users, :waiting_for_game
  end
end
