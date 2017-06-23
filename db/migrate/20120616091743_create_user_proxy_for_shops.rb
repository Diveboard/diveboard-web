class CreateUserProxyForShops < ActiveRecord::Migration
  def self.up
    Shop.includes(:user_proxy).each do |shop|
      next if !shop.user_proxy.nil?
      shop.create_proxy_user!
    end
  end

  def self.down
    Shop.includes(:user_proxy).each do |shop|
      next if shop.user_proxy.nil?
      shop.user_proxy.destroy
    end
  end
end
