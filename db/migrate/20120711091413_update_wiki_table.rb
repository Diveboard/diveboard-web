class UpdateWikiTable < ActiveRecord::Migration
require 'redcarpet'

  def self.up
    add_column :wikis, :object_id, :integer
    add_index :wikis, :object_id
    add_column :wikis, :object_type, "ENUM('Spot', 'Country', 'Location', 'Region')"
    add_index :wikis, :object_type
    add_column :wikis, :user_id, :integer
    add_index :wikis, :user_id
    add_column :wikis, :verified_user_id, :integer
    add_column :wikis, :data, :text, :limit => 10.megabytes ## we want a MEDIUMTEXT i.e 65537 to 16777216 bytes (16 MiB): MEDIUMBLOB or MEDIUMTEXT

    template_data = IO.read("templates/location.md")
    Wiki.all.each do |w|
      begin
        ##since grit sux, let's take advantage of the fact that reading a file gives us the latest version
        filepath = (w.directory+"/"+w.name+".md").gsub(" ","-")
        if (page = IO.read(filepath))== template_data
        else
          w.data = Redcarpet.new(page).to_html
          if w.data.match(/^<p>Nobody\ shared\ info\ about\ this\ location\ yet/)
            w.data = nil
          end
        end
        w.save
      rescue
        print $!.message + " on id #{w.id}\n"
      end
      if w.data.nil?
        w.destroy
      end
    end

    proper_wikis = Wiki.all.map &:id

    Spot.where("wiki_id is not null").each do |o|
      if !(proper_wikis.include? o.wiki_id)
        o.wiki_id = nil
        o.save
      end
      if !o.wiki_id.nil?
        w = Wiki.find(o.wiki_id)
        w.object_type = o.class.to_s
        w.object_id = o.id
        w.save
      end
    end
    Location.where("wiki_id is not null").each do |o|
      if !(proper_wikis.include? o.wiki_id)
        o.wiki_id = nil
        o.save
      end
      if !o.wiki_id.nil?
        w = Wiki.find(o.wiki_id)
        w.object_type = o.class.to_s
        w.object_id = o.id
        w.save
      end
    end
    Region.where("wiki_id is not null").each do |o|
      if !(proper_wikis.include? o.wiki_id)
        o.wiki_id = nil
        o.save
      end
      if !o.wiki_id.nil?
        w = Wiki.find(o.wiki_id)
        w.object_type = o.class.to_s
        w.object_id = o.id
        w.save
      end
    end
    Country.where("wiki_id is not null").each do |o|
      if !(proper_wikis.include? o.wiki_id)
        o.wiki_id = nil
        o.save
      end
      if !o.wiki_id.nil?
        w = Wiki.find(o.wiki_id)
        w.object_type = o.class.to_s
        w.object_id = o.id
        w.save
      end
    end

    Wiki.all.each do |w|
      w.user_id = 30 #they belong to me by default koz that's the way I like it
      w.verified_user_id = 30 ## they're all right :)
      w.save
    end




    remove_column :wikis, :latest
    remove_column :wikis, :current
    remove_column :wikis, :name
    remove_column :wikis, :directory
    remove_column :wikis, :url

    remove_column :spots, :wiki_id
    remove_column :countries, :wiki_id
    remove_column :locations, :wiki_id
    remove_column :regions, :wiki_id
  end

  def self.down
    remove_column :wikis, :parent_id
    remove_column :wikis, :data

    add_column :wikis, :latest, :integer
    add_column :wikis, :current, :integer
    add_column :wikis, :name, :integer
    add_column :wikis, :directory, :integer
    add_column :wikis, :url, :integer

    add_column :spots, :wiki_id, :integer
    add_column :countries, :wiki_id, :integer
    add_column :locations, :wiki_id, :integer
    add_column :regions, :wiki_id, :integer
  end
end