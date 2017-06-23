module NotificationHelper

  def NotificationHelper.mail_background_exception err, *texts
    error_tag = "#{$$}.#{Time.now.to_i}.#{Time.now.usec}"
    Rails.logger.error "Exception raised : #{err.message} : #{texts.join(' - ')}"
    Rails.logger.info "Tag for error : #{error_tag}"
    Rails.logger.debug err.backtrace if err.respond_to? :backtrace
    begin
      ExceptionNotifier::Notifier.background_exception_notification(err, :data => texts).deliver
    rescue
      Rails.logger.debug 'Initial exception :'
      Rails.logger.debug err.backtrace.join("\n")
      Rails.logger.error "EXCEPTION NOTIFICATION by mail FAILED !!!"
      Rails.logger.debug $!.message
      Rails.logger.debug $!.backtrace.join("\n")
    end
    return {:error_tag => error_tag}
  end

end
