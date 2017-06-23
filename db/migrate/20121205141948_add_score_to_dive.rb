class AddScoreToDive < ActiveRecord::Migration
  def self.up
     add_column :dives, :score, :integer, :default => -100, :null => false
     add_index(:dives, :score)
     Dive.all.each do |d|
      begin
        d.save!
      rescue
        Rails.logger.debug "Could not compute score for dive #{d.id}"
      end
     end
  end

  def self.down
    remove_column :dives, :score
  end
end
