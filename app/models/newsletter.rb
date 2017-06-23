require 'delayed_job'

class Newsletter < ActiveRecord::Base
  has_many :newsletter_users
  has_many :users, :through => :newsletter_users, :source => :recipient, :source_type => "User"

  def permalink
    "/community/newsletter/#{self.id}"
  end

  def fullpermalink option=nil
    option ||= :canonical
    HtmlHelper.find_root_for(option).chop + permalink
  end


  def subject
    if self.title.nil?  || self.title == ""
      t = It.it("Diveboard Newsletter", scope: ['model', 'newsletter'])
      d = I18n.l( (self.distributed_at || self.created_at ||Date.today).to_date, format: :long)
      return "#{t} - #{d}"
    else
      self.title
    end
  end

  ## delivers the email to an array of recipients
  def deliver selector, force=false
    #Making sure there's no other delivering process
    connection.execute "UPDATE newsletters set sending_pid = #{$$} where id = #{id} and sending_pid is NULL"
    self.reload
    if force then
      self.update_attribute :sending_pid, $$
    else
      connection.execute "UPDATE newsletters set sending_pid = #{$$} where id = #{id} and sending_pid is NULL"
      self.reload
      if self.sending_pid != $$ then
        Rails.logger.error "Another process sending mails is already running"
        return
      end
    end

    startTime = Time.now
    failed = []
    success = 0
    skipped = 0
    rcpt = User.where(selector)
    my_retry = 0
    rcpt.each do |u|
      begin
        self.reload
        Rails.logger.info("Ending mail delivery because we lost the PID lock") and break unless self.sending_pid == $$
        if self.users.where('users.id' => u.id).count > 0 then
          logger.debug "Email of newsletter #{self.id} to #{u.nickname} [#{u.id}] @ [#{u.contact_email}] has not been sent koz already sent"
          skipped +=1
        elsif !u.accept_newsletter_email?
          logger.debug "Email of newsletter #{self.id} to #{u.nickname} [#{u.id}] @ [#{u.contact_email}] has not been sent koz opt out"
          skipped +=1
        elsif u.contact_email.match(NOTIFICATION_MAIL_FILTER).nil? then
          logger.debug "Email of newsletter #{self.id} to #{u.nickname} [#{u.id}] @ [#{u.contact_email}] has not been sent due to FILTERING"
          skipped +=1
        else
          logger.debug "Email of newsletter #{self.id} to #{u.nickname} [#{u.id}] @ [#{u.contact_email}] starting (retry #{my_retry})"
          mail = NotifyUser.newsletter(self, u, u.contact_email).deliver
          self.users.push(u)
          success +=1
        end
        my_retry = 0
      rescue Timeout::Error
        logger.debug $!.message
        my_retry += 1
        logger.debug "SMTP timed out - retry : #{my_retry}"
        redo if my_retry < 3
        error_log = { :to => u.id, :error => "SMTP Timeout"}
        failed.push error_log
        my_retry = 0
      rescue
        logger.debug $!.message
        error_log = { :to => u.id, :error => $!.message }
        failed.push error_log
        my_retry = 0
      end
    end
    Rails.logger.info("Mail delivery ended correctly")
    endTime = Time.now
    data = {
      :id => self.id,
      :total => rcpt.count,
      :failed => failed,
      :success => success,
      :skipped => skipped,
      :subject => "Your Newsletter #{self.id} has been sent",
      :duration => (endTime-startTime),
      :startTime => startTime,
      :endTime => endTime
    }
    self.distributed_at = Time.now
    self.sending_pid = nil
    self.save
    mail = WorkersMailer.notify_task_finished(data).deliver
    return true
  end
  handle_asynchronously :deliver, :queue => :admin_tasks

  def reports
    r = read_attribute(:reports)
    return [] if r.nil?
    JSON.parse(r)
  end

  def reports=(arg)
    raise DBArgumentError.new "Must be an array" if arg.class != Array
    write_attribute(:reports, arg.to_json)
  end
end
