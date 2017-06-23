class AddDefaultValues < ActiveRecord::Migration
  def self.up
    change_column :dives, :time_in, :datetime, :null => false, :default => "2011-01-01".to_datetime
    change_column :dives, :duration, :integer, :null => false, :default => 0
    change_column :dives, :user_id, :integer, :null => false, :limit => 8
    change_column :dives, :spot_id, :integer, :null => false, :default => 1
    change_column :dives, :maxdepth, :decimal, :null => false, :default => 0, :precision => 8, :scale => 3
    change_column :dives, :privacy, :integer, :null => false, :default => 0
    change_column :users, :admin_rights, :integer, :null => false, :default => 0
    #change_column :users, :vanity_url, :string, :null => false
    change_column :users, :total_ext_dives, :integer, :null => false, :default => 0
    change_column :auth_tokens, :token, :string, :null => false
    change_column :auth_tokens, :user_id, :integer, :null => false, :limit => 8
    change_column :auth_tokens, :expires, :datetime, :null => false
    change_column :uploaded_profiles, :source, :text, :null => false, :default => ""
    change_column :uploaded_profiles, :data, :longtext, :null => false
    #change_column :dives_eolcnames, :dive_id, :integer, :null => false
    #change_column :dives_fish, :dive_id, :integer, :null => false
    #change_column :dives_fish, :fish_id, :integer, :null => false
    change_column :fish_frequencies, :gbif_id, :integer, :null => false
    change_column :fish_frequencies, :lat, :integer, :null => false
    change_column :fish_frequencies, :lng, :integer, :null => false
    change_column :fish_frequencies, :count, :integer, :null => false
    change_column :pictures, :url, :string, :null => false
    change_column :spots, :name, :string, :null => false
    change_column :spots, :lat, :float, :null => false
    change_column :spots, :long, :float, :null => false
    change_column :spots, :zoom, :integer, :null => false
    change_column :spots, :precise, :boolean, :null => false, :default => false
    #TODO : EOL*, REGION, LOCATION
  end

  def self.down
    change_column :dives, :time_in, :datetime, :null => true, :default => nil
    change_column :dives, :duration, :integer, :null => true, :default => nil
    change_column :dives, :user_id, :integer, :null => true, :limit => 8
    change_column :dives, :spot_id, :integer, :null => true, :default => nil
    change_column :dives, :maxdepth, :decimal, :null => true, :default => nil, :precision => 8, :scale => 3
    change_column :dives, :privacy, :integer, :null => true, :default => nil
    change_column :users, :admin_rights, :integer, :null => true, :default => nil
    #change_column :users, :vanity_url, :string, :null => true
    change_column :users, :total_ext_dives, :integer, :null => true, :default => 0
    change_column :auth_tokens, :token, :string, :null => true
    change_column :auth_tokens, :user_id, :integer, :null => true
    change_column :auth_tokens, :expires, :datetime, :null => true
    change_column :uploaded_profiles, :source, :text, :null => true, :default => nil
    change_column :uploaded_profiles, :data, :longtext, :null => true, :limit => 2147483647
    #change_column :dives_eolcnames, :dive_id, :integer, :null => true
    #change_column :dives_fish, :dive_id, :integer, :null => true
    #change_column :dives_fish, :fish_id, :integer, :null => true
    change_column :fish_frequencies, :gbif_id, :integer, :null => true
    change_column :fish_frequencies, :lat, :integer, :null => true
    change_column :fish_frequencies, :lng, :integer, :null => true
    change_column :fish_frequencies, :count, :integer, :null => true
    change_column :pictures, :url, :string, :null => true
    change_column :spots, :name, :string, :null => true
    change_column :spots, :lat, :float, :null => true
    change_column :spots, :long, :float, :null => true
    change_column :spots, :zoom, :integer, :null => true
    change_column :spots, :precise, :boolean, :null => true, :default => nil
  end
end
