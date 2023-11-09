class CreateGames < ActiveRecord::Migration[6.1]
  def change
    create_table :games do |t|
      t.integer :gameStateA
      t.integer :gameStateB
      t.references :chatroom, null: true, foreign_key: true

      t.timestamps
    end
  end
end
