class EmailSubscription < ActiveRecord::Base
  self.set_table_name "email_subscriptions" ##otherwise Rails' plural was stupid

  belongs_to :recipient, :polymorphic => true


  def self.can_email?(recipient, scope)
    ##should check wether this email is opt out from such scope

    if recipient.class.to_s == "String"
      return false if recipient.blank?
      sub = EmailSubscription.where ({
          :email => recipient,
          :scope => scope,
          :recipient_id => nil,
          :recipient_type => nil
        })
    else
      return false if recipient.respond_to?(:contact_email) && recipient.contact_email.blank?
      sub = EmailSubscription.where ({
          :recipient_type => recipient.class.to_s,
          :recipient_id => recipient.id,
          :scope => scope
        })
    end
    return true if sub.empty?
    return true if sub.first.subscribed.nil?
    return sub.first.subscribed
  end



  def self.change_subscription(recipient, scope, value)
    raise DBArgumentError.new "value can only be true or false" unless value == true || value == false
    raise DBArgumentError.new "scope can't be nil" if scope.nil?
    raise DBArgumentError.new "recipient can't be nil" if recipient.nil?

    if recipient.class.to_s == "String"
      sub = EmailSubscription.find_or_create_by ({
          :email => recipient,
          :scope => scope,
          :recipient_id => nil,
          :recipient_type => nil
        })
    else
      sub = EmailSubscription.find_or_create_by ({
          :recipient => recipient,
          :scope => scope
        })
      #sub.email = recipient.contact_email ##may not be such a good idea....
    end
    sub.subscribed = value
    sub.save
    return sub
  end

  def self.find_or_create_by(opts)
    target = EmailSubscription
    opts.keys.each {|k|
      if begin opts[k].has_attribute?(:id) rescue false end
        target = target.where((k.to_s+"_id").to_sym => opts[k].id)
        target = target.where((k.to_s+"_type").to_sym => opts[k].class.to_s)
      else
        target = target.where(k => opts[k])
      end
    }
    return target.first unless target.empty?
    return EmailSubscription.create(opts)
  end





  def email=(val)
    ## TODO check that email is valid
    write_attribute(:email, val)
  end


end
