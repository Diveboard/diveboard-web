class DanMailer < ActionMailer::Base
  default :from => "logs@diveboard.com",
  :content_type => "text/html",
  :to => Rails.application.config.dan_export_mailto

  def send_zxl(dive_id, content)
    attachments["diveboard-#{dive_id}.zxl"] = content
    mail( :subject => Rails.application.config.dan_export_prefix+" ZXL export [#{dive_id}] "+DateTime.now.to_s)
  end
end
