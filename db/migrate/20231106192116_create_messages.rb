class CreateMessages < ActiveRecord::Migration[6.1]
  def change
    create_table :messages do |t|
      t.text :content
      t.references :user, index: true, foreign_key: true
      t.references :chatroom, index: true, foreign_key: true

      t.timestamps
    end
  end
end
