class CreateIndexesOnTables < ActiveRecord::Migration
  def self.up
    remove_index :profile_data, :dive_id
    add_index :users, :vanity_url
    add_index :users, :fb_id
    add_index :auth_tokens, :token
    add_index :auth_tokens, :user_id
    add_index :pictures, [:dive_id, :updated_at]
    add_index :dives, [:user_id, :time_in]
    add_index :dives, [:spot_id, :time_in]
    add_index :eolcnames, :eolsname_id
    add_index :dives_eolcnames, :dive_id
    add_index :dives_eolcnames, :cname_id
    add_index :dives_eolcnames, :sname_id
    add_index :dives, :time_in
    add_index :pictures, :updated_at
    add_index :profile_data, [:dive_id, :seconds]
  end

  def self.down
    remove_index :users, :vanity_url
    remove_index :users, :fb_id
    remove_index :auth_tokens, :token
    remove_index :auth_tokens, :user_id
    remove_index :pictures, :column => [:dive_id, :updated_at]
    remove_index :dives, :column => [:user_id, :time_in]
    remove_index :dives, :column => [:spot_id, :time_in]
    remove_index :eolcnames, :eolsname_id
    remove_index :dives_eolcnames, :dive_id
    remove_index :dives_eolcnames, :cname_id
    remove_index :dives_eolcnames, :sname_id
    remove_index :dives, :time_in
    remove_index :pictures, :updated_at
    remove_index :profile_data, :column => [:dive_id, :seconds]
    add_index :profile_data, :dive_id
  end
end
