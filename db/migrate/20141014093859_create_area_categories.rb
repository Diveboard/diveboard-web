class CreateAreaCategories < ActiveRecord::Migration
  def change
    create_table :area_categories do |t|
      t.belongs_to :area
      t.string :category
      t.integer :count

      t.timestamps
    end
  end
end
