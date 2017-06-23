class AddPreferredLocaleToUser < ActiveRecord::Migration
  def change
    add_column :users, :preferred_locale, :string, nil: false, default: 'en'
  end
end
