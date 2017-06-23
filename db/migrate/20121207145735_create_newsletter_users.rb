class CreateNewsletterUsers < ActiveRecord::Migration
  def self.up
    create_table :newsletter_users do |t|
      t.integer :newsletter_id
      t.integer :recipient_id
      t.string :recipient_type
      t.timestamps
    end
    add_column :newsletters, :reports, :text

  end

  def self.down
    drop_table :newsletter_users
    remove_column :newsletters, :reports
  end
end
