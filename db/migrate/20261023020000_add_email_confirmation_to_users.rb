class AddEmailConfirmationToUsers < ActiveRecord::Migration
  def up
    add_column :users, :email_confirmed_at, :datetime
    add_column :users, :email_confirmation_token, :string
    add_index :users, :email_confirmation_token

    # Every account that already exists counts as confirmed. The gate is for new signups; without
    # this the 103,311 existing users would all be treated as unconfirmed and lose posting.
    execute "UPDATE users SET email_confirmed_at = created_at WHERE email_confirmed_at IS NULL"
  end

  def down
    remove_index :users, :email_confirmation_token
    remove_column :users, :email_confirmation_token
    remove_column :users, :email_confirmed_at
  end
end
