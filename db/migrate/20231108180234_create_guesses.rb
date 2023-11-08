class CreateGuesses < ActiveRecord::Migration[6.1]
  def change
    create_table :guesses do |t|
      t.string :word
      t.string :score
      t.integer :liePosition
      t.integer :lieDirection
      t.string :marks
      t.boolean :isCorrect
      t.integer :guessNumber
      t.references :game, null: false, foreign_key: true

      t.timestamps
    end
  end
end
