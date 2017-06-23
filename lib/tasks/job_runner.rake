
namespace :jobs do

  desc "restarting delayed job workers"
  task :restart => :environment do |t,args|
    ["jobs:stop", "jobs:start"].each do |t|
      Rake::Task[t].execute
    end
  end


  desc "starting delayed job workers"
  task :start, [:nb] => :environment do |t, args|
    Rails.logger.info "Starting workers '#{Rails.application.config.workers_process_name}'"
    new_workers = args[:nb] || Rails.application.config.workers_count
    new_workers.to_i.times do |n|
      pid = fork do 
        #workers exit when database conncetion is lost....
        $0=Rails.application.config.workers_process_name
        begin
          Rails.logger.debug "Preparing worker '#{n}'"
          worker = Delayed::Worker.new
          if n == 0 then
            worker.queues = [nil, 'default', 'admin_tasks']
          else
            worker.queues = [nil, 'default']
          end
          worker.name = 'worker-' + n.to_s
          Rails.logger.info "Starting worker '#{worker.name}'"
          worker.start
        rescue
          Rails.logger.error "Delayed job wants to quit... But I own him, so work again bitch ! (#{$!.message})"
          sleep 5
          begin
            ActiveRecord::Base.connection.reconnect!
          rescue
          end
          retry
        end
      end
      Process.detach(pid)
    end  
  end

  desc "stopping all delayed job worker"
  task :stop => :environment do
    Rails.logger.auto_flushing = true
    Rails.logger.info "Stopping workers '#{Rails.application.config.workers_process_name}'"

    IO.popen("ps -ef | grep '#{Rails.application.config.workers_process_name}' | grep -v 'grep'") { |io| 
      while (line = io.gets) do 
        begin
          pid = line.match(/^ *[^ ]* *([0-9]*)/)[1]
          Rails.logger.debug "Killing (gently?) PID ##{pid}"
          system "kill -15 #{pid}"
        rescue
          Rails.logger.warn "Trouble while killing your workers... Did they join a labor union?"
          Rails.logger.info "They said : #{$!.message}"
        end
      end }
  end

  desc "checking status of job workers"
  task :dbcheck => :environment do
    Rails.logger.auto_flushing = true
    begin 
      running_procs = []
      IO.popen("ps auwwx | grep '#{Rails.application.config.workers_process_name}' | grep -v 'grep'") { |io| while (line = io.gets) do running_procs.push line.chomp end }
      Rails.logger.debug "Found #{running_procs.length} workers running named #{Rails.application.config.workers_process_name} #{[nil, running_procs].flatten.join "\nworkers : "}"

      if running_procs.length < Rails.application.config.workers_count then
        nb_to_launch = Rails.application.config.workers_count - running_procs.length
        Rake::Task['jobs:start'].invoke(nb_to_launch)
        sleep 3
        running_procs = []
        IO.popen("ps auwwx | grep '#{Rails.application.config.workers_process_name}' | grep -v 'grep'") { |io| while (line = io.gets) do running_procs.push line.chomp end }
        Rails.logger.debug "Found #{running_procs.length} workers running named #{Rails.application.config.workers_process_name} #{[nil, running_procs].flatten.join "\nworkers : "}"
      end

      failed_jobs = Delayed::Job.all.reject{|j| j.last_error.nil? || j.alert_ignore }
      todo_jobs = Delayed::Job.all.reject{|j| j.attempts >= Delayed::Worker.max_attempts || j.alert_ignore}
      old_jobs = todo_jobs.clone.reject{|j| j.alert_ignore || j.created_at + Rails.application.config.workers_maxold_warn > Time.now}

      if running_procs.length != Rails.application.config.workers_count then
        Rails.logger.error "Your workers are on strike ! #{running_procs.length} processes found - #{Rails.application.config.workers_count} expected "
        Rails.logger.info running_procs.join("\nWorker : ")
        LogMailer.send_worker_down(running_procs).deliver
      elsif todo_jobs.length > Rails.application.config.workers_maxqueue_warn then
        Rails.logger.warn "There are too many (#{todo_jobs.length}) jobs in the queue"
        LogMailer.send_worker_down(running_procs).deliver
      elsif old_jobs.length > 0 then
        Rails.logger.warn "There are #{old_jobs.length} old jobs in the queue"
        LogMailer.send_worker_down(running_procs).deliver
      elsif failed_jobs.length > 0 then
        Rails.logger.warn "There are #{failed_jobs.length} jobs that have failed"
        LogMailer.send_worker_down(running_procs).deliver
      end

      User.transaction do
        failed_jobs.each do |j| j.update_attribute :alert_ignore, true end
      end

    rescue
      Rails.logger.error "Issue while flogging the workers : #{$!.message}"
    end
  end
end


