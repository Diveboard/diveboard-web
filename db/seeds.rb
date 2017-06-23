# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

Dive.create(
  :id => '1',
  :time_in => '2011-01-01 00:00:00.000000',
  :duration => '00',
  :spot_id => '1',
  :maxdepth => '0',
  :temp_surface => '0',
  :temp_bottom => '0'
)

Spot.create(
  :id => '1',
  :name => 'New Dive',
  :location => 'location',
  :region => 'region/sea',
  :long =>'0.0',
  :lat => '0.0',
  :zoom => '1.0'
)