class WorkersMailer < ActionMailer::Base
  default :from => "logs@diveboard.com",
    :content_type => "text/html",
    :to => Rails.application.config.plugin_log_mailto

  def send_info_down(arg_data)
    @data = arg_data
    mail( :subject => Rails.application.config.workers_log_prefix+"Your workers are on strike "+DateTime.now.to_s)
  end

  def notify_task_finished(data)
    @data = data
    mail( :subject => @data[:subject])
  end
end
