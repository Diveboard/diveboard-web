Delayed::Worker.lifecycle.before(:enqueue) do |job|
  # If Locale is not set
  if(job.locale.nil? || job.locale.empty? && I18n.locale.to_s != I18n.default_locale.to_s)
    job.locale = I18n.locale
  end
end



Delayed::Worker.lifecycle.around(:invoke_job) do |job, &block|
  # Store locale of worker
  savedLocale = I18n.locale
  begin
    # Set locale from job or if not set use the default
    if(job.locale.nil?)
      I18n.locale = I18n.default_locale
    else
      I18n.locale = job.locale
    end
    # now really perform the job
    block.call(job)
  ensure
    # Clean state from before setting locale
    I18n.locale = savedLocale
  end
end
