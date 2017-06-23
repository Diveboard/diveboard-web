if Rails.env != 'production'
  class OverrideMailReciptient
    def self.delivering_email(mail)
      need_rewrite = false
      mail.to.each do |e|
        need_rewrite = true unless e.match(NOTIFICATION_MAIL_FILTER)
      end
      if need_rewrite then
        mail.to = Rails.application.config.mailer_log_mailto
        mail.subject = Rails.application.config.mailer_log_prefix + mail.subject
      end
    end
  end
  ActionMailer::Base.register_interceptor(OverrideMailReciptient)
end

