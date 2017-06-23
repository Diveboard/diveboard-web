module ShopClaimHelper

  def ShopClaimHelper.generate_url_confirm_claim(user, group, source=nil)
    salt = rand(100000)
    sign = ShopClaimHelper.generate_signature_claim(user.id, group.id, salt, source)
    source = source.gsub(/[^A-Za-z0-9-]/, '') unless source.nil? # Underscores would conflict with the separator used
    return (group.fullpermalink(:canonical)+"?valid_claim=#{salt}_#{user.id}_#{group.id}_#{sign}#{"_" unless source.blank?}#{source}")
  end

  def ShopClaimHelper.generate_signature_claim(user_id, group_id, salt, source)
    return Digest::MD5.hexdigest("Diveboard Claim #{user_id} => #{group_id} [#{salt}]#{source}")
  end

  def ShopClaimHelper.check_claim_user(claim_string)
    raise DBArgumentError.new "No claim provided" if claim_string.blank?
    raise DBArgumentError.new "Invalid claim format" if !claim_string.match(/^[0-9]+_[0-9*]+_[0-9]+_[0-9a-f]+(_[A-Za-z0-9-]*)?$/)

    args = claim_string.split('_')
    salt = args[0]
    user_id = args[1]
    group_id = args[2]
    sign = args[3]
    source = args[4]
    raise DBArgumentError.new "Invalid signature" if sign != ShopClaimHelper.generate_signature_claim(user_id, group_id, salt, source)

    user = User.find(user_id) rescue nil unless user_id == '*'
    group = User.find(group_id) rescue nil
    raise DBArgumentError.new "Invalid user for claim" if user_id != '*' && user.nil?
    #raise DBArgumentError.new "The claim has been filed by '#{user.name}' and must be validated by himself." if user_id != @user.id && @user.admin_rights < 4
    raise DBArgumentError.new "Invalid group for claim" if group.nil?

    return {:user => user, :group => group, :claim => claim_string, :source => source}
  end

end
