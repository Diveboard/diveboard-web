class RepurposeUnsubscribe < ActiveRecord::Migration
  def self.up
    rename_table "unsubscribes", "email_subscriptions"
    add_column :email_subscriptions, :subscribed, :boolean
    add_column :email_subscriptions, :recipient_type, :string
    add_column :email_subscriptions, :recipient_id, :integer


    ##Default unsubscribes to false
    EmailSubscription.all.each {|e| e.subscribed = false; e.save}
    
    ##Migrate user settings
    User.all.each{|e|
      EmailSubscription.change_subscription(e, "weekly_notif_email",  e.read_attribute(:accept_weekly_notif_email)) unless e.read_attribute(:accept_weekly_notif_email).nil?
      EmailSubscription.change_subscription(e, "instant_notif_email",  e.read_attribute(:accept_instant_notif_email)) unless e.read_attribute(:accept_instant_notif_email).nil?
      EmailSubscription.change_subscription(e, "weekly_digest_email",  e.read_attribute(:accept_weekly_digest_email)) unless e.read_attribute(:accept_weekly_digest_email).nil?
      EmailSubscription.change_subscription(e, "newsletter_email",  e.read_attribute(:accept_newsletter_email)) unless e.read_attribute(:accept_newsletter_email).nil?
    }

    remove_column :users, :accept_weekly_notif_email
    remove_column :users, :accept_instant_notif_email
    remove_column :users, :accept_weekly_digest_email
    remove_column :users, :accept_newsletter_email

  end

  def self.down
    rename_table "email_subscriptions", "unsubscribes"
    remove_column :unsubscribes, :subscribed
    remove_column :unsubscribes, :recipient_type
    remove_column :unsubscribes, :recipient_id
    add_column :users, :accept_weekly_notif_email, :boolean
    add_column :users, :accept_instant_notif_email, :boolean
    add_column :users, :accept_weekly_digest_email, :boolean
    add_column :users, :accept_newsletter_email, :boolean
  end
end
