class DropProfileDataOnDives < ActiveRecord::Migration
  def up
    remove_column :dives, :profile_data 
  end

  def down
    add_column :dives, :profile_data, :text
  end
end
