class AddTripIdToDives < ActiveRecord::Migration
  def self.up
    add_column :dives, :trip_id, :integer
    begin
      Dive.transaction do
        Dive.where('trip_name is not null').each do |dive|
          trip_name = dive.read_attribute 'trip_name'
          next if trip_name.blank?
          trip = Trip.where(:user_id => dive.user_id, :name => trip_name).first
          if trip.nil? then
            trip = Trip.create(:user_id => dive.user_id, :name => trip_name)
          end
          execute "UPDATE dives set trip_id=#{trip.id} where id=#{dive.id}"
        end
      end
      remove_column :dives, :trip_name
    rescue
      puts $!.to_s
      puts $!.backtrace.join "\n"
      remove_column :dives, :trip_id
      raise $!
    end
  end

  def self.down
    add_column :dives, :trip_name, :string rescue nil
    Dive.transaction do
      Dive.where('trip_id is not null').each do |dive|
        next unless dive.read_attribute('trip_name').nil?
        dive.trip_name = dive.trip.name
        dive.save!
      end
    end
    remove_column :dives, :trip_id
  end
end
