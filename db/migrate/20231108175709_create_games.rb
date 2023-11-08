class CreateGames < ActiveRecord::Migration[6.1]
  def change
    create_table :games do |t|
      t.integer :stateA
      t.integer :stateB
      t.integer :playerA
      t.integer :playerB
      t.string :candidateWordsForA # The
      t.string :candidateWordsForB
      t.string :finalWordForA
      t.string :finalWordForB
      t.integer :wordIndexForA
      t.integer :wordIndexForB
      t.references :chatroom, null: true, foreign_key: true

      t.timestamps
    end
  end
end
