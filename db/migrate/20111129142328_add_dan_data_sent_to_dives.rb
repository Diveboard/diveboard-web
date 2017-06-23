class AddDanDataSentToDives < ActiveRecord::Migration
  def self.up
    add_column :dives, :dan_data_sent, :longtext
  end

  def self.down
    remove_column :dives, :dan_data_sent
  end
end
