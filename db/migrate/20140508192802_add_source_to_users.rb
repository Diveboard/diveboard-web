class AddSourceToUsers < ActiveRecord::Migration
  def change
    add_column :users, :source, :string
  end
end
