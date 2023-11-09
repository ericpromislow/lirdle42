class CreateGameStates < ActiveRecord::Migration[6.1]
  def change
    create_table :game_states do |t|
      t.integer :state
      t.integer :playerID
      t.string :candidateWords
      t.string :finalWord
      t.integer :wordIndex
      t.references :game, null: true, foreign_key: true

      t.timestamps
    end
  end
end
