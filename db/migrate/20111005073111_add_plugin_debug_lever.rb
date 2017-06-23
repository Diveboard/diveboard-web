class AddPluginDebugLever < ActiveRecord::Migration
  def self.up
    add_column :users, :plugin_debug, "ENUM('DEBUG', 'INFO', 'ERROR')"
    #execute("UPDATE users SET plugin_debug='INFO'")
  end
  def self.down
    remove_column :users, :plugin_debug
  end
end
