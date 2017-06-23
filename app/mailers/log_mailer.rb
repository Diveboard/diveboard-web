class LogMailer < ActionMailer::Base
  default :from => "plugin@diveboard.com",
    :content_type => "text/html",
    :to => Rails.application.config.plugin_log_mailto

  def send_logs(arg_data)
    @data = arg_data
    subject = Rails.application.config.plugin_log_prefix+"Plugin logs "
    if !@data['user_id'].blank? then
      subject += "for user #{@data['user_id']} on #{DateTime.now.strftime("%Y-%m-%d")}"
    else
      subject += DateTime.now.strftime("%Y-%m-%d %H:%M:%S")
    end
    mail(:subject => subject)
  end

  def send_worker_down(arg_data)
    @data = arg_data
    mail( :subject => Rails.application.config.workers_log_prefix+"Your workers are on strike "+DateTime.now.to_s)
  end

  def notify_rate_limit_exceeded(request)
    @data = request.env
    mail( :subject => "Rate limit exceeded on API by #{request.env['HTTP_X_FORWARDED_FOR']}")
  end

  def report_exception(e, additional_message=nil)
    @additional_message = additional_message || "None"
    @exc = e
    mail( :subject => Rails.application.config.workers_log_prefix+"A non breaking exception happened #{@exc.message} "+DateTime.now.to_s)
  end
end
