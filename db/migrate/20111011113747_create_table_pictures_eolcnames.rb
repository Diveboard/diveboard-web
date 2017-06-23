class CreateTablePicturesEolcnames < ActiveRecord::Migration
  def self.up
    create_table :pictures_eolcnames, :id => false do |t|
      t.references :picture
      t.references :sname
      t.references :cname
    end
  end

  def self.down
    drop_table :pictures_eolcnames
  end
end
