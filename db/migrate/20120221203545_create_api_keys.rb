class CreateApiKeys < ActiveRecord::Migration
  def self.up
    create_table :api_keys do |t|
      t.string :key
      t.integer :user_id
      t.text :comment

      t.timestamps
    end
    add_index :api_keys, :key
    add_index :api_keys, :user_id
    ApiKey.create(:key => "px6LQxmV8wQMdfWsoCwK", :user_id => 30, :comment => "mobile_app")
  end

  def self.down
    drop_table :api_keys
  end
end
