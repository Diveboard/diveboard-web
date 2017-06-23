class ActionMailer::Base

  # Set headers for SendGrid.
private
  def add_sendgrid_headers(action, args)
    mailer = self.class.name
    args = Hash[ method(action).parameters.map(&:last).zip(args) ]
    headers "X-SMTPAPI" => {
      category:    [ mailer, "#{mailer}##{action}" ],
      unique_args: { environment: Rails.env}
    }.to_json
  end

end