class CreateTreasures < ActiveRecord::Migration
  def change
    create_table :treasures do |t|
      t.integer :user_id
      t.string :object_type
      t.integer :object_id
      t.string :campaign_name

      t.timestamps
    end
  end
end
