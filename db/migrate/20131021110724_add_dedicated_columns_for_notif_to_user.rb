class AddDedicatedColumnsForNotifToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :accept_weekly_notif_email, :boolean, :default => true
    add_column :users, :accept_instant_notif_email, :boolean, :default => true
    add_column :users, :accept_weekly_digest_email, :boolean, :default => true
    add_column :users, :accept_newsletter_email, :boolean, :default => true

    User.all.each do |u| u.update_attribute :accept_newsletter, JSON.parse(u.settings)["opt_in"] rescue nil end
    User.all.each do |u| u.update_attribute :accept_instant_notif_email, JSON.parse(u.settings)["comments_notifs"] rescue nil end
  end

  def self.down
    remove_column :users, :accept_weekly_notif_email
    remove_column :users, :accept_instant_notif_email
    remove_column :users, :accept_weekly_digest_email
    remove_column :users, :accept_newsletter_email
  end
end
