class AddValidationFlagsOnTables < ActiveRecord::Migration
  def self.up
    ## will add verified_user_id verified_date to the tables that need verification
    add_column :spots, :verified_user_id, :integer
    add_column :spots, :verified_date, :datetime

    add_column :locations, :verified_user_id, :integer
    add_column :locations, :verified_date, :datetime

    add_column :regions, :verified_user_id, :integer
    add_column :regions, :verified_date, :datetime

    remove_column :locations, :flag_moderate_private_to_public
    remove_column :locations, :private_user_id

    remove_column :regions, :flag_moderate_private_to_public
    remove_column :regions, :private_user_id

    ##tag moderated spots to moderate
    execute("UPDATE spots set flag_moderate_private_to_public=true WHERE moderate_id is NOT NULL")
    ##validate initial spots
    execute("UPDATE spots set verified_date=created_at, verified_user_id=30, flag_moderate_private_to_public=NULL WHERE moderate_id is NULL AND created_at < '2011-06-01'")    
    Spot.where(:flag_moderate_private_to_public => true) do |s|
      if s.dives.blank? && !s.moderate_id.nil?
        ##if a spot is private and a moderate of another spot and has no dives...
        ##we can remove it an merge it in his daddy
        s.merge_into s.moderate_id 
      end
    end
  end

  def self.down
    remove_column :spots, :verified_user_id
    remove_column :spots, :verified_date

    remove_column :locations, :verified_user_id
    remove_column :locations, :verified_date

    remove_column :regions, :verified_user_id
    remove_column :regions, :verified_date


    add_column :locations, :flag_moderate_private_to_public, :boolean
    add_column :locations, :private_user_id, :integer

    add_column :regions, :flag_moderate_private_to_public, :boolean
    add_column :regions, :private_user_id, :integer
  end
end
