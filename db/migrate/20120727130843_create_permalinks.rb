class CreatePermalinks < ActiveRecord::Migration
  def self.up
    add_column :spots, :redirect_id, :integer
    remove_column :spots, :blob
    add_column :locations, :redirect_id, :integer
    remove_column :locations, :blob
    add_column :regions, :redirect_id, :integer
    remove_column :regions, :blob

    add_column :spots, :from_bulk, :boolean
    add_column :spots, :within_country_bounds, :boolean
    #add_index :spots, :from_bulk
    #add_index :spots, :within_country_bounds
    Spot.all.each do |s|
      s.check_country_bounds
      s.save
    end

    Spot.includes(:dives => :uploaded_profile).each do |s|
      if (s.dives.map do |d| d.uploaded_profile.source end .uniq rescue nil) == ['file'] then
        s.from_bulk = true;
        s.save
        end
    end

    Location.where("nesw_bounds is NOT NULL").each do |l|
      l.nesw_bounds = nil
      l.save
    end
    Region.where("nesw_bounds is NOT NULL").each do |l|
      l.nesw_bounds = nil
      l.save
    end
=begin
    Location.all.each do |l|
      l.update_bounds
      sleep(1)
    end

    Region.all.each do |l|
      l.update_bounds
      sleep(1)
    end
=end

  end
  def self.down
    remove_column :spots, :redirect_id
    add_column :spots, :blob, :string
    remove_column :locations, :redirect_id
    add_column :locations, :blob, :string
    remove_column :regions, :redirect_id
    add_column :regions, :blob, :string

    remove_column :spots, :from_bulk
    add_column :spots, :within_country_bounds
  end
end
