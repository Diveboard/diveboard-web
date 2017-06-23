class AddMovescountToUser < ActiveRecord::Migration
  def change
    add_column :users, :movescount_email, :string
    add_column :users, :movescount_userkey, :string
  end
end
