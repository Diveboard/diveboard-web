class FixEmptyPicturesHref < ActiveRecord::Migration
  def self.up
    Picture.all.each do |pict|
      if pict.href.nil? || pict.href.empty?
        pict.href = pict.url
        pict.save
      end
    end
  end

  def self.down
  end
end
