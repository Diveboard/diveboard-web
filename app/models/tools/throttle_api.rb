class ThrottleApi

  WHITELIST = ['127.0.0.1', '88.191.143.60', '192.168.56.101', '84.99.202.37', '46.23.73.29', '86.73.74.201', '84.103.205.101', '85.170.14.213', '195.154.92.60', 
    '167.114.21.248', #teamcity new
    '37.59.152.57' #ksso.net
  ]
  GREYLIST = []
  BLACKLIST = ["65.32.98.14"]


  def self.allowed? request, user=nil

    return true unless request.path.match(/^\/api\//)
    return true if request.path.match(/^\/api\/js_logs/)
    return true if whitelisted?(request, user)
    Rails.logger.info("Rejecting user because blacklisted") and return false if blacklisted?(request, user)

    counts = cache_get(request, user)
    count_noauth = counts['count_noauth'].to_i rescue 0
    count_auth = counts['count_auth'].to_i rescue 0
    if user.nil? then
      count_noauth = count_noauth + 1 rescue 1
    else
      count_auth = count_auth + 1 rescue 1
    end

    allowed = (count_auth <= max_allowed(request, true)) && (count_noauth <= max_allowed(request, false))
    begin
      cache_set(request, user, count_noauth, count_auth)
    rescue => e
      Rails.logger.warn "Throttle API rate limit failed to update value : #{$!.message}"
      allowed = true
    end

    if count_noauth == 1 + max_allowed(request, false).to_i then
      Rails.logger.warn "Throttle API public rate limit reached"
      LogMailer.notify_rate_limit_exceeded(request).deliver
    end
    if count_auth == 1 + max_allowed(request, true).to_i then
      Rails.logger.warn "Throttle API private rate limit reached"
      LogMailer.notify_rate_limit_exceeded(request).deliver
    end
    return allowed
  end

  def self.max_allowed request, user
    return 5000 if user
    return 400
  end

  def self.whitelisted? request, user
    return WHITELIST.include?(request.env['HTTP_X_FORWARDED_FOR'])
  end

  def self.blacklisted? request, user
    return BLACKLIST.include?(request.env['HTTP_X_FORWARDED_FOR'])
  end

  def self.greylisted? request, user
    return GREYLIST.include?(request.env['HTTP_X_FORWARDED_FOR'])
  end

  def self.cache_get request, user
    Media.select_all_sanitized("select count_noauth, count_auth from api_throttle where lookup = :k", :k => cache_key_for(request, user)).first
  end

private

  def self.cache_set request, user, count_noauth, count_auth
    Media.execute_sanitized "insert into api_throttle (lookup, count_noauth, count_auth) VALUES (:key, :count_noauth, :count_auth) ON DUPLICATE KEY UPDATE count_noauth=:count_noauth, count_auth=:count_auth", :key => cache_key_for(request, user), :count_auth => count_auth, :count_noauth => count_noauth
    return val
  end

  def self.cache_key_for request, user
    [request.env['HTTP_X_FORWARDED_FOR'], Time.now.strftime('%Y-%m-%d')].join(":")
  end

end
