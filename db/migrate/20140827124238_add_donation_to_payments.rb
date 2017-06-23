class AddDonationToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :donation, :integer
  end
end
