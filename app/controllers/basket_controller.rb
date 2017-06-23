
class BasketController < ApplicationController
  before_filter :init_logged_user, :prevent_browser_cache, :init_basket

  def view
    render :layout => false, :locals => {:interactive => true, :baskets => @baskets}
  end

  def get_basket
    render :json => {:success => true, :result => @baskets.to_api(:items, :private => true)}
  end

  def add_to_basket
    begin
      basket_item = filter_basket_item JSON.parse(params[:elt])

      unlock_basket_for(basket_item.shop_id)

      #Get the basket for the shop or create a new one
      logger.debug @baskets.inspect
      logger.debug basket_item.inspect
      basket = @baskets[basket_item.shop_id]
      if basket.nil?
        basket = Basket.create do |b|
          b.user_id = @user.id rescue nil
          b.shop_id = basket_item.shop_id
        end
        @baskets[basket_item.shop_id] = basket
        session[:baskets].push basket.id
      end

      #assign the new item to the basket
      basket_item.basket_id = basket.id

      basket.save!
      basket_item.save!

      init_basket
      render :json => {:success => true, :basket_item_id => basket_item.id, :result => @baskets.to_api(:items, :private => true)}
    rescue
      #trace the error
      logger.warn $!.message
      logger.debug $!.backtrace.join "\n"
      render api_exception $!
      return
    end
  end

  def reset_basket
    trash_basket
    init_basket
    render :json => {:success => true, :result => @baskets.to_api(:items, :private => true)}
  end


  def remove_from_basket
    begin
      item = BasketItem.find(params[:id].to_i)
      basket = @baskets[item.shop_id]
      raise DBArgumentError.new "This basket does not belong to you" unless ownz_basket basket
      if @baskets[item.shop_id].status == 'open' then
        item.destroy
      else
        unlock_basket_for item.shop_id, :except => item
      end

      init_basket
      render :json => {:success => true, :basket_item_id => item.id, :result => @baskets.to_api(:items, :private => true)}
    rescue
      #trace the error
      logger.warn $!.message
      logger.debug $!.backtrace.join "\n"
      render api_exception $!
      return
    end
  end


  def update_in_basket
    item = BasketItem.find(params[:id].to_i)
    basket = @baskets[item.shop_id]
    raise DBArgumentError.new "This basket does not belong to you" unless ownz_basket basket
    if basket.status == 'open' then
      new_item = filter_basket_item JSON.parse(params[:elt]), item
      new_item.save!
      render :json => {:success => true, :basket_item_id => new_item.id, :result => @baskets.to_api(:items, :private => true)}
    else
      basket.reopen! :except => item
      init_basket
      add_to_basket
    end

  end


  def paypal_start
    begin
      raise DBArgumentError.new "You must be authenticated" unless @user

      basket = Basket.find(params[:basket_id].to_i)

      if basket.user_id.nil? then
        basket.user_id = @user.id
        basket.save!
      end

      if @user.id != basket.user_id then
        render :layout => false, :json => {:success => false, :error => 'This basket does not belong to you' }
        return
      end

      if !session[:baskets].include?(basket.id) then
        render :layout => false, :json => {:success => false, :error => 'This basket is no longer valid in this session' }
        return
      end

      paypal_url = Basket.checkout_list([basket])
      render :layout => false, :json => {:success => true, :url =>  paypal_url }
    rescue
      logger.warn $!.message
      logger.debug $!.backtrace.join "\n"
      render api_exception $!
    end
  end




  def manage_confirm
    begin
      raise DBArgumentError.new "You must be authenticated" unless @user
      basket = begin Basket.decode_reference(params[:basket_id]) rescue raise DBArgumentError.new "Basket not found" end
      raise DBArgumentError.new "You don't have the rights on this basket" unless basket.shop.is_private_for? :caller => @user

      basket.note_from_shop = params[:note] unless params[:note].blank?
      basket.confirm!

      render :json => {:success => true, :result => basket.to_api(:private, :caller => @user), :user_authentified => !@user.nil?}
    rescue
      logger.warn $!.message
      logger.debug $!.backtrace.join "\n"
      render api_exception $!
    end
  end

  def manage_deliver
    begin
      raise DBArgumentError.new "You must be authenticated" unless @user
      basket = begin Basket.decode_reference(params[:basket_id]) rescue raise DBArgumentError.new "Basket not found" end
      raise DBArgumentError.new "You don't have the rights on this basket" unless basket.shop.is_private_for? :caller => @user

      begin
        basket.note_from_shop = params[:note] unless params[:note].blank?
      rescue DBException => e
        InternalMessage.create :from_id => @user.id,
          :from_group_id => basket.shop.user_proxy.id,
          :to_id => basket.user_id,
          :topic => "Delivery notice",   #todo: i18n
          :message => params[:note],
          :in_reply_to => basket
      end
      basket.deliver!

      render :json => {:success => true, :result => basket.to_api(:private, :caller => @user), :user_authentified => !@user.nil?}
    rescue
      logger.warn $!.message
      logger.debug $!.backtrace.join "\n"
      render api_exception $!
    end
  end



  def manage_ask_detail
    begin
      raise DBArgumentError.new "You must be authenticated" unless @user
      basket = begin Basket.decode_reference(params[:basket_id]) rescue raise DBArgumentError.new "Basket not found" end
      raise DBArgumentError.new "You don't have the rights on this basket" unless basket.shop.is_private_for? :caller => @user
      raise DBArgumentError.new "A message must be supplied when pausing a basket" if params[:message].blank?

      InternalMessage.create :from_id => @user.id,
        :from_group_id => basket.shop.user_proxy.id,
        :to_id => basket.user_id,
        :topic => "Information request",   #todo: i18n
        :message => params[:message],
        :in_reply_to => basket

      basket.hold!

      render :json => {:success => true, :result => basket.to_api(:private, :caller => @user), :user_authentified => !@user.nil?}
    rescue
      logger.warn $!.message
      logger.debug $!.backtrace.join "\n"
      render api_exception $!
    end
  end


  def manage_reject
    begin
      raise DBArgumentError.new "You must be authenticated" unless @user
      basket = begin Basket.decode_reference(params[:basket_id]) rescue raise DBArgumentError.new "Basket not found" end

      #Case #1: the user asks to cancel his own basket when paid
      if basket.status == 'paid' && basket.user.is_private_for?({:caller => @user}) then
        basket.cancel!
      else
        raise DBArgumentError.new "You don't have the rights on this basket" unless basket.shop.is_private_for? :caller => @user
        raise DBArgumentError.new "A message must be supplied when rejecting a basket" if params[:message].blank?

        basket.cancel!

        InternalMessage.create :from_id => @user.id,
          :from_group_id => basket.shop.user_proxy.id,
          :to_id => basket.user_id,
          :topic => "Your order cannot be completed",   #todo: i18n
          :message => params[:message],
          :in_reply_to => basket
      end

      render :json => {:success => true, :result => basket.to_api(:private, :caller => @user), :user_authentified => !@user.nil?}
    rescue
      logger.warn $!.message
      logger.debug $!.backtrace.join "\n"
      render api_exception $!
    end
  end

private

  def trash_basket
    session[:baskets] = []
    @baskets.each do |shop_id, basket|
      basket.trash
    end
    init_basket
  end

  def unlock_basket
    @baskets.each do |shop_id, basket|
      next if basket.status == 'open'
      @baskets[:shop_id] = basket.reopen!
      session[:baskets].reject! do |id| id == basket.id end
      session[:baskets].push @baskets[shop_id]
    end
  end

  def unlock_basket_for(shop_id, args={})
    old_basket = @baskets[shop_id]
    return if old_basket.nil?
    return if old_basket.status == 'open'
    @baskets[shop_id] = old_basket.reopen! args
    session[:baskets].reject! do |id| id == old_basket.id end
    session[:baskets].push @baskets[shop_id]
    return
  end

  def filter_basket_item req, item = nil
    good_to_sell = GoodToSell.find(req['id'].to_i)
    raise DBArgumentError.new "quantity must be integer" if req['quantity'].nil? || req['quantity'].to_i < 0

    case good_to_sell.realm
      when 'dive' then
        filtered_details = ValidationHelper.validate_and_filter_parameters req['details'], {:class => Hash,
          :sub => {
            'date_type' => { :class => String, :in => ['one', 'period'], :presence => true, :nil => false },
            'date_at' => { :class => Date, :presence => false, :convert_if_string => Date.method(:parse)},
            'date_from' => { :class => Date, :presence => false, :convert_if_string => Date.method(:parse)},
            'date_to' => { :class => Date, :presence => false, :convert_if_string => Date.method(:parse)},
            'pref_when' => {:class => String, :presence => false, :nil => true},
            'constraints' => {:class => String, :presence => false, :nil => true},
            'contact' => {:class => String, :presence => false, :nil => true},
            'comment' => {:class => String, :presence => false, :nil => true},
            'divers' => {
              :class => Array, :sub => {
                :class => Hash,
                :sub => {
                  'certification' => {:class => String},
                  'quantity' => {:class => Fixnum, :convert_if_string => lambda {|s| s.to_i } },
                }
              }
            }
          }
        }

        if filtered_details['date_type'] == 'one' then
          filtered_details.except! 'date_from', 'date_to'
          raise DBArgumentError.new "date_at must be filled with date_type 'one'" if filtered_details['date_at'].blank?
        elsif filtered_details['date_type'] == 'period' then
          filtered_details.except! 'date_at'
          raise DBArgumentError.new "date_from must be filled with date_type 'one'" if filtered_details['date_from'].blank?
          raise DBArgumentError.new "date_to must be filled with date_type 'one'" if filtered_details['date_to'].blank?
        end

        deposit_option = (req['deposit_option']=='true') rescue false
        if item.nil?
          return BasketItem.new :good_to_sell_id => good_to_sell.id, :quantity => req['quantity'].to_i, :details => filtered_details, :deposit_option => deposit_option
        else
          item.quantity = req['quantity'].to_i
          item.details = filtered_details
          return item
        end
      else
        raise DBArgumentError.new "Unsupported stuff", realm: good_to_sell.realm
    end
  end


  def ownz_basket basket
    if basket.nil? then
      return false
    elsif @user then
      return basket.user_id == @user.id
    else
      return @baskets[basket.shop_id] == basket
    end
  end


end