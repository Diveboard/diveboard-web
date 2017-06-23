class RecreateGeonamesAlternateNames < ActiveRecord::Migration
  def self.up
    drop_table :geonames_alternate_names_utf8 rescue nil

    create_table(:geonames_alternate_names_utf8, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8') do |t|
      t.integer :geoname_id
      t.string :language, :length => 7
      t.string :name
      t.boolean :preferred
      t.boolean :short_name
      t.boolean :colloquial
      t.boolean :historic
    end

    execute 'truncate table geonames_alternate_names_utf8'
    execute 'alter table geonames_alternate_names_utf8 MODIFY id INT NOT NULL'
    execute 'alter table geonames_alternate_names_utf8 drop primary key'

    `cd /tmp && curl -O http://download.geonames.org/export/dump/alternateNames.zip && unzip alternateNames.zip`
    execute "load data infile '/tmp/alternateNames.txt' into table geonames_alternate_names_utf8"

    execute 'alter table geonames_alternate_names_utf8 MODIFY id INT NOT NULL PRIMARY KEY AUTO_INCREMENT'
    add_index :geonames_alternate_names_utf8, :name

    execute 'RENAME table geonames_alternate_names to geonames_alternate_names_latin, geonames_alternate_names_utf8 to geonames_alternate_names'

    `cd /tmp && rm -f alternateNames.*`

  end

  def self.down
    execute 'RENAME table geonames_alternate_names to geonames_alternate_names_utf8, geonames_alternate_names_latin to geonames_alternate_names' rescue nil
    drop_table :geonames_alternate_names_utf8
  end
end
