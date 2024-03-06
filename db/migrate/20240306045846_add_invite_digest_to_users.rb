class AddInviteDigestToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :invite_digest, :string
    add_column :users, :invite_sent_at, :datetime
  end
end
