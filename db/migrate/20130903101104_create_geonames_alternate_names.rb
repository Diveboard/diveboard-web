class CreateGeonamesAlternateNames < ActiveRecord::Migration
  def self.up
    create_table :geonames_alternate_names do |t|
      t.integer :geoname_id
      t.string :language, :length => 7
      t.string :name
      t.boolean :preferred
      t.boolean :short_name
      t.boolean :colloquial
      t.boolean :historic
    end

    execute 'truncate table geonames_alternate_names'
    execute 'alter table geonames_alternate_names MODIFY id INT NOT NULL'
    execute 'alter table geonames_alternate_names drop primary key'

    `cd /tmp && curl -O http://download.geonames.org/export/dump/alternateNames.zip && unzip alternateNames.zip`
    execute "load data infile '/tmp/alternateNames.txt' into table geonames_alternate_names"

    execute 'alter table geonames_alternate_names MODIFY id INT NOT NULL PRIMARY KEY AUTO_INCREMENT'
    add_index :geonames_alternate_names, :name

    `cd /tmp && rm -f alternateNames.*`

  end

  def self.down
    drop_table :geonames_alternate_names
  end
end
