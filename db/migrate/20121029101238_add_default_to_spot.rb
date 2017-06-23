class AddDefaultToSpot < ActiveRecord::Migration
  def self.up
    change_column_default :spots, :country_id, 1
    change_column_default :spots, :location_id, 1
    change_column_default :spots, :lat, 0.0
    change_column_default :spots, :long, 0.0
    change_column_default :spots, :zoom, 7
  end

  def self.down
    change_column_default :spots, :country_id, nil
    change_column_default :spots, :location_id, nil
    change_column_default :spots, :lat, nil
    change_column_default :spots, :long, nil
    change_column_default :spots, :zoom, nil
  end
end
