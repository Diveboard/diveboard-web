class CreateNewsletters < ActiveRecord::Migration
  def self.up
    create_table :newsletters do |t|
      t.text :html_content
      t.timestamps
      t.datetime :distributed_at
    end
  end

  def self.down
    drop_table :newsletters
  end
end
