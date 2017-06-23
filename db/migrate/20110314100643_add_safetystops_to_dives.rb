class AddSafetystopsToDives < ActiveRecord::Migration
  def self.up
    add_column :dives, :safetystops, :string
    Dive.create(
      :id => '1',
      :time_in => '2011-01-01 00:00:00.000000',
      :duration => '00',
      :spot_id => '1',
      :maxdepth => '0',
      :temp_surface => '0',
      :temp_bottom => '0',
      :safetystops => '[]',
      :privacy => true
    )

  end

  def self.down
    remove_column :dives, :safetystops
  end
end
