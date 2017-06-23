class WidgetProfile
  include Widget
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming


  attr_accessor :id, :shop_id, :shop, :user_proxy

  def self.find id, *args

    w = WidgetProfile.new
    w.id = id
    w.shop_id = id
    w.shop = Shop.find(id) rescue nil
    w.user_proxy = w.shop.user_proxy rescue nil
    Rails.logger.debug "WidgetProfile Load with id #{id}"
    return w
  end

  def self.base_class
    return self
  end

  def destroyed?
    return false
  end

  def new_record?
    return false
  end

  def destroy
  end

  def save!
  end

  def reviews
    shop.reviews
  end

  def update_widget data, shop
    return if data["content"].blank? #nothing to do

    if !data["content"]["profile_picture_id"].blank?
      begin
        Rails.logger.debug "Updating shop profile picture with pict #{data["content"]["profile_picture_id"]}"
        p = Picture.find(data["content"]["profile_picture_id"].to_i)
        FileUtils.cp p.original_image_path, "public/user_images/#{self.user_proxy.id.to_s}.png"
        self.user_proxy.pict = true
        self.user_proxy.save
      rescue
        Rails.logger.debug "Updating shop profile picture failed"
        Rails.logger.debug $!.message
        Rails.logger.debug $!.backtrace
      end
    end
  end

end