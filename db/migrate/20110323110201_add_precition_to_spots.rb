class AddPrecitionToSpots < ActiveRecord::Migration
  def self.up
    add_column :spots, :precise, :boolean
    #update the seed record
    Spot.create(
      :id => '1',
      :name => 'New Dive',
      :location => 'location',
      :region => 'region/sea',
      :long =>'0.0',
      :lat => '0.0',
      :zoom => '1.0',
      :country => 'blank',
      :precise => false
    )
  end

  def self.down
    remove_column :spots, :precise
  end
end
