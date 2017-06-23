class AddCacheToPictures < ActiveRecord::Migration
  def self.up
    remove_timestamps :dives_eolcnames
    
    add_column :pictures, :cache, :string
    
    Picture.all.each do |pict|
      pict.cache_image
    end
    
  end

  def self.down
    remove_column :pictures, :cache
    add_timestamps :dives_eolcnames
    
  end
end
