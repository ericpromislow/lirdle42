class AddCurrentGuessToGameState < ActiveRecord::Migration[6.1]
  def change
    add_column :game_states, :pending_guess, :string
  end
end
