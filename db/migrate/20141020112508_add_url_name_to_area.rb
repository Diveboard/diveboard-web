class AddUrlNameToArea < ActiveRecord::Migration
  def change
    add_column :areas, :url_name, :string
    Area.reset_column_information
    Area.all.each do |a|
      a.save
    end
  end
end
