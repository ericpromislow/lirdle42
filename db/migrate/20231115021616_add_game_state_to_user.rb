class AddGameStateToUser < ActiveRecord::Migration[6.1]
  def change
    add_reference :users, :game_state, null: true, foreign_key: true
  end
end
