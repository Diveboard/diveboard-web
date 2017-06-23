class CreateStats < ActiveRecord::Migration
  def self.up
    drop_table :stats_logs rescue nil
    drop_table :stats_sums rescue nil

    create_table :stats_logs, :id => false do |t|
      t.timestamp :time
      t.integer :sub_count
      t.string :ip
      t.string :method
      t.string :url
      t.string :params
      t.string :ref
      t.string :status
      t.string :user_agent
    end

    create_table :stats_sums, :id => false do |t|
      t.string :aggreg
      t.timestamp :time
      t.string :col1
      t.string :col2
      t.integer :nb
    end

    add_index :stats_sums, [:aggreg, :time, :col1, :col2]

  end

  def self.down
    drop_table :stats_logs
    drop_table :stats_sums
  end
end
