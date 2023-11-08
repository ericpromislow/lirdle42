class CreateInvitations < ActiveRecord::Migration[6.1]
  def change
    create_table :invitations do |t|
      t.integer :from, null: false
      t.integer :to, null: false

      t.timestamps
    end
  end
end
