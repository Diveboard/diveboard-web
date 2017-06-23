class AddContactEmailToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :contact_email, :string
    
  end

  def self.down
    remove_column :users, :contact_email
  end
end
