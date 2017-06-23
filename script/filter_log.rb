#!/usr/bin/ruby

require 'zlib'

### Start of configuration ###

#Default timespan
span = {
  :from => Time.now.strftime('%Y-%m-%d 00:00'),
  :to =>   Time.now.strftime('%Y-%m-%d 23:60')
}

#filter : only requests matching all the following details are displayed
filter = {}


#output should be :logs or :json or :csv or a string for printing only a variable
output = :json

priority = 19
filename = File.join(File.dirname($0), "..", "log", "#{ENV['RAILS_ENV'] || "production"}.log")
from_stdin = !STDIN.tty?
capture_params = false
output_stream_file = nil
output_overwrite = false
timed = false


### help function ###
def help
  puts <<EOF

Filters rails production logs based on date, and several other elements. The output can be either an abstract (one line per request) or the full logs for the request. Default is to print all of today's logs.

Available options are :
 Input/Output options:
    --input file  takes a file (plain or gziped) as input
    --output file outputs everything in file instead of STDOUT
    --timed       prepends the date of the first log to output filename
    --overwrite   force to overwrite file if already exists

 General options:
    --logs        outputs the full log instead of an abstract
    --csv         outputs the abstract as a CSV
    --print arg   only prints the 'arg' value for each matching request
    --help        prints this help and exits
    --priority N  process nice value. Default is 19.
    --with-params also stores the parameters in the abstract

 Time filters:
    --today, --yesterday, --anytime
    --from "YYYY-MM-DD", --from "YYYY-MM-DD HH:MM", --to "YYYY-MM-DD", --to "YYYY-MM-DD HH:MM"

 Request filters:
    --pid N       pid of the rails worker handling the request
    --ip N        ip from where the request comes
    --overtime N  minimum response time in milliseconds
    --user_id N   Diveboard user_id (can be 'public' for not logged users, 'missing' when authentication is disabled)
    --method XXX  HTTP request method (POST, GET, ...)
                  If XXX starts and ends with '/' then XXX is parsed as a Regexp
    --url XXX     Request URL
                  If XXX starts and ends with '/' then XXX is parsed as a Regexp
    --format XXX  Requested format (HTML, JSON, ...)
                  If XXX starts and ends with '/' then XXX is parsed as a Regexp
    --apikey XXX  Api key used
                  If XXX starts and ends with '/' then XXX is parsed as a Regexp
    --status XXX  Returned status (200 OK, ...)
                  If XXX starts and ends with '/' then XXX is parsed as a Regexp
    --action XXX  Controller#method
                  If XXX starts and ends with '/' then XXX is parsed as a Regexp

EOF
end

### Args processing ###'

arg_idx = 0
until arg_idx >= ARGV.length do
  arg = ARGV[arg_idx]
  case arg
    when '--help' then
      help
      exit(0)
    when '--priority' then
      val = ARGV[arg_idx+1]
      if val.nil? then
        STDERR.puts "Missing value for #{arg}"
        exit(1)
      end
      if val.match(/^[0-9-]*$/) && val.to_i <= 20 && val.to_i > -20 then
        val = val.to_i
      else
        STDERR.puts "Invalid value #{val} for #{arg}"
        exit(1)
      end
      key = arg.gsub(/^--/, '').to_sym
      filter[key] = val
      arg_idx += 1

    when '--logs' then output = :logs
    when '--csv' then output = :csv
    when '--today' then
      span = {
        :from => Time.now.strftime('%Y-%m-%d 00:00'),
        :to =>   Time.now.strftime('%Y-%m-%d 23:60')
      }
    when '--yesterday' then
      span = {
        :from => (Time.now-1.day).strftime('%Y-%m-%d 00:00'),
        :to =>   (Time.now-1.day).strftime('%Y-%m-%d 23:60')
      }
    when '--anytime' then
      span = {
        :from => '0000',
        :to => '9999'
      }
    when '--with-params' then
      capture_params = true
    when '--from', '--to' then
      val = ARGV[arg_idx+1]
      if val.nil? then
        STDERR.puts "Missing value for #{arg}"
        exit(1)
      end
      if !val.match(/^[0-9]{4}-[0-9]{2}-[0-9]{2}( [0-9:]*)?$/) then
        STDERR.puts "Invalid value #{val} for #{arg}"
        exit(1)
      end
      key = arg.gsub(/^--/, '').to_sym
      span[key] = val
      arg_idx += 1

    when '--pid', '--overtime' then
      val = ARGV[arg_idx+1]
      if val.nil? then
        STDERR.puts "Missing value for #{arg}"
        exit(1)
      end
      if val.match(/^[0-9]*$/) then
        val = val.to_i
      else
        STDERR.puts "Invalid value #{val} for #{arg}"
        exit(1)
      end
      key = arg.gsub(/^--/, '').to_sym
      filter[key] = val
      arg_idx += 1

    when '--user_id' then
      val = ARGV[arg_idx+1]
      if val.nil? then
        STDERR.puts "Missing value for #{arg}"
        exit(1)
      end
      if val.match(/^[0-9]*$/) then
        val = val.to_i
      elsif ['missing', 'public'].include?(val) then
        val = val.to_sym
      else
        STDERR.puts "Invalid value #{val} for #{arg}"
        exit(1)
      end
      key = arg.gsub(/^--/, '').to_sym
      filter[key] = val
      arg_idx += 1

    when '--input' then
      val = ARGV[arg_idx+1]
      if val.nil? then
        STDERR.puts "Missing value for #{arg}"
        exit(1)
      end
      from_stdin = false
      filename = val
      arg_idx += 1

    when '--output' then
      val = ARGV[arg_idx+1]
      if val.nil? then
        STDERR.puts "Missing value for #{arg}"
        exit(1)
      end
      output_stream_file = val
      arg_idx += 1

    when '--timed' then
      timed = true

    when '--overwrite' then
      output_overwrite = true

    when '--url', '--format', '--status', '--action', '--ip', '--method', '--apikey' then
      val = ARGV[arg_idx+1]
      if val.nil? then
        STDERR.puts "Missing value for #{arg}"
        exit(1)
      end
      if val.match(/^\/.*\/$/) then
        val = Regexp.new(val.gsub(/^\//,'').gsub(/\/$/,''))
      end
      key = arg.gsub(/^--/, '').to_sym
      filter[key] = val
      arg_idx += 1

    when '--print' then
      val = ARGV[arg_idx+1]
      if val.nil? then
        STDERR.puts "Missing value for #{arg}"
        exit(1)
      end
      output = val
      arg_idx += 1

  else
    STDERR.puts "Unknown argument #{arg}"
    exit(1)
  end
  arg_idx += 1
end


### End of configuration ###

Process.setpriority(Process::PRIO_PROCESS, 0, priority) rescue STDERR.puts $!.message


def date_at f, pos
  f.pos = pos
  f.gets
  line = f.gets
  return line.match("^([0-9 :.-]*) -")[1]
end

def init_cursor f
  last_line = `tail -n 1 '#{f.path}'`
  pos_a = 0
  pos_b = f.size - last_line.length - 1
  date_a = date_at f, pos_a
  date_b = date_at f, pos_b

  return ({
    :pos_a => pos_a,
    :pos_b => pos_b,
    :date_a => date_a,
    :date_b => date_b
  })
end


def iter_dicho f, cursor, target
  new_cursor = cursor.dup

  new_pos = (cursor[:pos_a] + (cursor[:pos_b] - cursor[:pos_a])/2).to_i
  new_date = date_at f, new_pos

  if new_date < target then
    new_cursor[:pos_a] = new_pos
    new_cursor[:date_a] = new_date
  else
    new_cursor[:pos_b] = new_pos
    new_cursor[:date_b] = new_date
  end
  return new_cursor
end


class LogFilter
  def initialize(filter={}, capture_params=false, output=:json, output_stream)
    @abstract = {}
    @logs = {}
    @filter = filter.dup
    @output = output
    @csv_keys = []
    @capture_params = capture_params
    @output_stream = output_stream
  end
  def feed line
    m = line.match /^([0-9 ._:-]*) - INFO - #([0-9]*) -.*Started ([A-Z_.-]*)[^"]*"([^"]*)" for ([0-9.]*) / rescue return
    if m then
      time = m[1]
      pid = m[2]
      method = m[3]
      url = m[4]
      ip = m[5]

      #initialize tracking object
      @abstract[pid] = {
        :pid => pid,
        :url => url,
        :method => method,
        :ip => ip,
        :user_id => :missing,
        :start_time => time
      }
      @logs[pid] = ""

    end


    if @output == :logs then
      m = line.match /^[0-9 :_-]* - [A-Z]* - #([0-9]*) -/
      if m then
        pid = m[1]
        return unless @logs[pid]
        @logs[pid] += line
      end
    end

    m = line.match /- INFO - #([0-9]*) - *Processing by ([^ ]*) as (.*)/
    if m then
      pid = m[1]
      action = m[2]
      format = m[3]
      return unless @abstract[pid]
      @abstract[pid][:action] = action
      @abstract[pid][:format] = format
    end

    m = line.match /- INFO - #([0-9]*) -   Parameters: .*"apikey"=>"([^"]*)"/
    if m then
      pid = m[1]
      apikey = m[2]
      return unless @abstract[pid]
      @abstract[pid][:apikey] = apikey
    end

    m = line.match /- INFO - #([0-9]*) -   Parameters: (.*)/
    if m then
      pid = m[1]
      params = m[2]
      return unless @abstract[pid]
      return unless @capture_params
      @abstract[pid][:params] = params
    end

    m = line.match /- #([0-9]*) .* Unknown user - session will be public/
    if m then
      pid = m[1]
      return unless @abstract[pid]
      @abstract[pid][:user_id] = :public
    end

    m = line.match /- #([0-9]*) .* (User already authentified and exists, id =|User auth by cookie - updating tokens number) ([0-9]*)/
    if m then
      pid = m[1]
      user_id = m[3].to_i
      return unless @abstract[pid]
      @abstract[pid][:user_id] = user_id
    end

    m = line.match /- INFO - #([0-9]*) - Completed (.*) in ([0-9.]*)ms/
    if m then
      pid = m[1]
      status = m[2]
      time = m[3].to_i

      return unless @abstract[pid]
      @abstract[pid][:status] = status
      @abstract[pid][:time] = time

      #see if it's interesting
      interesting = true
      interesting &&= @abstract[pid][:pid] == @filter[:pid] if @filter[:pid]
      interesting &&= @abstract[pid][:ip] == @filter[:ip] if @filter[:ip]
      interesting &&= @abstract[pid][:action] == @filter[:action] if @filter[:action].is_a? String
      interesting &&= @abstract[pid][:action].match(@filter[:action]) if @filter[:action].is_a? Regexp
      interesting &&= @abstract[pid][:url] == @filter[:url] if @filter[:url].is_a? String
      interesting &&= @abstract[pid][:url].match(@filter[:url]) if @filter[:url].is_a? Regexp
      interesting &&= @abstract[pid][:status] == @filter[:status] if @filter[:status].is_a? String
      interesting &&= @abstract[pid][:status].match(@filter[:status]) if @filter[:status].is_a? Regexp
      interesting &&= @abstract[pid][:status].to_i == @filter[:status] if @filter[:status].is_a? Fixnum
      interesting &&= @abstract[pid][:format] == @filter[:format] if @filter[:format].is_a? String
      interesting &&= @abstract[pid][:format].match(@filter[:format]) if @filter[:format].is_a? Regexp
      interesting &&= @abstract[pid][:time] > @filter[:overtime] if @filter[:overtime]
      interesting &&= @abstract[pid][:user_id] == @filter[:user_id] if @filter[:user_id]

      #prints results if interesting
      if interesting then
        if @output == :logs then
          @output_stream.puts @logs[pid]
        elsif @output == :json then
          @output_stream.puts @abstract[pid]
        elsif @output == :csv then
          @abstract[pid].keys.each do |k|
            @csv_keys.push(k) unless @csv_keys.include?(k)
          end
          line = @csv_keys.map do |k| '"' + @abstract[pid][k].gsub("\\", "\\\\").gsub("\"","\\\"") + '"' rescue "\\N" end
          @output_stream.puts line.join ','
        elsif @output.is_a? String then
          @output_stream.puts @abstract[pid][@output.to_sym]
        else
          @output_stream.puts @abstract[pid]
        end
      end

      #reset for parallel requests counts
      @abstract[pid] = nil
      @logs[pid] = nil
    end
  end
end


if from_stdin then
  f = STDIN
  is_streaming = true
else
  f = begin
    Zlib::GzipReader.open(filename)
  rescue Zlib::GzipFile::Error => e
    nil
  end
  #If a gzip file, then we stream from that file
  is_streaming = !f.nil?
  f ||= File.new(filename, "rb")
end

if output_stream_file.nil? then
  output_stream = STDOUT
elsif timed && !from_stdin
  begin
    line = nil
    first_time = nil
    #reads the first lines to get a timestamp
    10.times do
      line = f.gets
      first_time = line.match("^([0-9 :.-]*) -")[1] rescue nil
      break unless first_time.nil?
    end
    f.rewind
    first_time = line.match("^([0-9 :.-]*) -")[1]
    first_date = line.split(" ")[0]
    first_date.gsub!("-", "")
    timed_output_stream_file = File.join( File.dirname(output_stream_file), "#{first_date}_#{File.basename(output_stream_file)}")
    if !output_overwrite && File.exists?(timed_output_stream_file) then
      STDERR.puts "Output file already exists : #{timed_output_stream_file}"
      exit(1)
    end
    output_stream = File.open(timed_output_stream_file, "w")
  rescue
    if !output_overwrite && File.exists?(output_stream_file) then
      STDERR.puts "Output file already exists : #{output_stream_file}"
      exit(1)
    end
    output_stream = File.open(output_stream_file, "w")
  end
else
  if !output_overwrite && File.exists?(output_stream_file) then
    STDERR.puts "Output file already exists : #{output_stream_file}"
    exit(1)
  end
  output_stream = File.open(output_stream_file, "w")
end

logfilter = LogFilter.new(filter, capture_params, output, output_stream)

if is_streaming then
  while l=f.gets do
    logfilter.feed l
  end
else
  target_a = span[:from]
  target_b = span[:to]

  cursor = init_cursor f
  while cursor[:pos_a] + 100 < cursor[:pos_b] do
    cursor = iter_dicho f, cursor, target_a
  end

  start_pos = cursor[:pos_a]


  cursor = init_cursor f
  while cursor[:pos_a] + 100 < cursor[:pos_b] do
    cursor = iter_dicho f, cursor, target_b
  end

  end_pos = cursor[:pos_b]

  f.pos = start_pos
  f.gets
  while f.pos < end_pos
    logfilter.feed f.gets
  end
end
