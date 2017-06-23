class AddSessionsTable < ActiveRecord::Migration
  def self.up
    create_table :sessions do |t|
      t.string :session_id, :null => false
      t.text :data
      t.timestamps
    end

    add_index :sessions, :session_id
    add_index :sessions, :updated_at
    

    execute("UPDATE `users` set `contact_email` = LOWER(`email`)")
    execute("UPDATE `users` set `email` = NULL")
    
    
    
  end

  def self.down
    drop_table :sessions
  end
end
