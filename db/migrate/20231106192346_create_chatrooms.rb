class CreateChatrooms < ActiveRecord::Migration[6.1]
  def change
    create_table :chatrooms do |t|
      t.boolean :is_lobby, default: false
      t.string :topic
      t.string :slug

      t.timestamps
    end
  end
end
