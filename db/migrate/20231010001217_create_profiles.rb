class CreateProfiles < ActiveRecord::Migration[6.1]
  def change
    create_table :profiles do |t|
      t.integer :theme
      t.float :karma

      t.timestamps
    end
  end
end
