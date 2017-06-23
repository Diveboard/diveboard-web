class UpdateCountryAndLocation1 < ActiveRecord::Migration
  def self.up
    execute "update countries set cname='' where id=1"
    execute "update locations set name='' where id=1"
  end

  def self.down
    execute "update countries set cname='country' where id=1"
    execute "update locations set name='location' where id=1"
  end
end
