module RequestLogAnalyzer::Tracker

  # Determines the average hourly spread of the parsed requests.
  # This spread is shown in a graph form.
  #
  # Accepts the following options:
  # * <tt>:if</tt> Proc that has to return !nil for a request to be passed to the tracker.
  # * <tt>:line_type</tt> The line type that contains the duration field (determined by the category proc).
  # * <tt>:output</tt> Direct output here (defaults to STDOUT)
  # * <tt>:unless</tt> Proc that has to return nil for a request to be passed to the tracker.
  #
  # Expects the following items in the update request hash
  # * <tt>:timestamp</tt> in YYYYMMDDHHMMSS format.
  #
  # Example output:
  #  Requests graph - average per day per hour
  #  --------------------------------------------------
  #    7:00 - 330 hits        : =======
  #    8:00 - 704 hits        : =================
  #    9:00 - 830 hits        : ====================
  #   10:00 - 822 hits        : ===================
  #   11:00 - 823 hits        : ===================
  #   12:00 - 729 hits        : =================
  #   13:00 - 614 hits        : ==============
  #   14:00 - 690 hits        : ================
  #   15:00 - 492 hits        : ===========
  #   16:00 - 355 hits        : ========
  #   17:00 - 213 hits        : =====
  #   18:00 - 107 hits        : ==
  #   ................
  class DailySpread < Base

    attr_reader :day_frequencies, :first, :last

    # Check if timestamp field is set in the options and prepare the result time graph.
    def prepare
      options[:field] ||= :timestamp
      @day_frequencies = (0..6).map { 0 }
      @first, @last = 99999999999999, 0
    end

    # Check if the timestamp in the request and store it.
    # <tt>request</tt> The request.
    def update(request)
      timestamp = request.first(options[:field])
      weekday = Date.strptime(timestamp.to_s[0..7], "%Y%m%d").wday
      @day_frequencies[weekday] +=1
      @first = timestamp if timestamp < @first
      @last  = timestamp if timestamp > @last
    end

    # Total amount of requests tracked
    def total_requests
      @day_frequencies.inject(0) { |sum, value| sum + value }
    end


    # First timestamp encountered
    def first_timestamp
      DateTime.parse(@first.to_s, '%Y%m%d%H%M%S') rescue nil
    end

    # Last timestamp encountered
    def last_timestamp
      DateTime.parse(@last.to_s, '%Y%m%d%H%M%S') rescue nil
    end

    # Difference between last and first timestamp.
    def timespan
      last_timestamp - first_timestamp
    end
    
    # Generate an hourly spread report to the given output object.
    # Any options for the report should have been set during initialize.
    # <tt>output</tt> The output object
    def report(output)
      output.title(title)

      if total_requests == 0
        output << "None found.\n"
        return
      end

      output.table({}, {:align => :right}, {:type => :ratio, :width => :rest, :treshold => 0.15}) do |rows|
        @day_frequencies.each_with_index do |requests, index|
          ratio            = requests.to_f / @day_frequencies.max.to_f
          rows << ["#{Date::DAYNAMES[index]}", "%d hits" % requests, ratio]
        end
      end
    end

    # Returns the title of this tracker for reports
    def title
      options[:title] || "Request distribution per day"
    end

    # Returns the found frequencies per hour as a hash for YAML exporting
    def to_yaml_object
      yaml_object = {}
      @day_frequencies.each_with_index do |freq, index|
        yaml_object["#{Date::DAYNAMES[index]}"] = freq
      end
      yaml_object
    end
  end


  class HourlySpread < Base
    def total_requests
      @hour_frequencies.max rescue 0
    end
  end
end


module RequestLogAnalyzer::FileFormat

  # Default FileFormat class for Rails 3 logs.
  #
  # For now, this is just a basic implementation. It will probaby change after
  # Rails 3 final has been released.
  class RequestLogAnalyzerCustomFormat < Base

    extend CommonRegularExpressions

    # beta4: Started GET "/" for 127.0.0.1 at Wed Jul 07 09:13:27 -0700 2010 (different time format)
    line_definition :started do |line|
      line.header = true
      line.teaser = /Started /
      line.regexp = /Started ([A-Z]+) (?:\x1B\[(?:[0-9]{1,2}(?:;[0-9]{1,2})*)?[m|K])?"([^"]+)" for (#{ip_address}) at (#{timestamp('%a %b %d %H:%M:%S %z %Y')}|#{timestamp('%Y-%m-%d %H:%M:%S %z')})/

      line.capture(:method)
      line.capture(:path)
      line.capture(:ip)
      line.capture(:timestamp).as(:timestamp)
    end

    # Processing by QueriesController#index as HTML
    line_definition :processing do |line|
      line.teaser = /Processing by /
      line.regexp = /Processing by ([A-Za-z0-9\-:]+)\#(\w+) as ([\w\/\*]*)/

      line.capture(:controller)
      line.capture(:action)
      line.capture(:format)
    end

    # Parameters: {"action"=>"cached", "controller"=>"cached"}
    line_definition :parameters do |line|
      line.teaser = /\bParameters:/
      line.regexp = /\bParameters:\s+(\{.*\})/
      line.capture(:params).as(:eval)
    end

    # Completed 200 OK in 224ms (Views: 200.2ms | ActiveRecord: 3.4ms)
    # Completed 302 Found in 23ms
    # Completed in 189ms
    line_definition :completed do |line|
      line.footer = true
      line.teaser = /Completed /
      line.regexp = /Completed (\d+)? .*in (\d+(?:\.\d+)?)ms(?:[^\(]*\(Views: (\d+(?:\.\d+)?)ms .* ActiveRecord: (\d+(?:\.\d+)?)ms.*\))?/

      line.capture(:status).as(:integer)
      line.capture(:duration).as(:duration, :unit => :msec)
      line.capture(:view).as(:duration, :unit => :msec)
      line.capture(:db).as(:duration, :unit => :msec)
    end

    # ActionController::RoutingError (No route matches [GET] "/missing_stuff"):
    line_definition :routing_errors do |line|
      line.teaser = /RoutingError/
      line.regexp = /No route matches \[([A-Z]+)\] "([^"]+)"/
      line.capture(:missing_resource_method).as(:string)
      line.capture(:missing_resource).as(:string)
    end

    # ActionView::Template::Error (undefined local variable or method `field' for #<Class>) on line #3 of /Users/willem/Code/warehouse/app/views/queries/execute.csv.erb:
    line_definition :failure do |line|
      line.footer = true
      line.regexp = /((?:[A-Z]\w*[a-z]\w+\:\:)*[A-Z]\w*[a-z]\w+) \((.*)\)(?: on line #(\d+) of (.+))?\:\s*$/

      line.capture(:error)
      line.capture(:message)
      line.capture(:line).as(:integer)
      line.capture(:file)
    end

    # Rendered queries/index.html.erb (0.6ms)
    line_definition :rendered do |line|
      line.compound = [:partial_duration]
      line.teaser = /\bRendered /
      line.regexp = /\bRendered ([a-zA-Z0-9_\-\/.]+(?:\/[a-zA-Z0-9_\-.]+)+)(?:\ within\ .*?)? \((\d+(?:\.\d+)?)ms\)/
      line.capture(:rendered_file)
      line.capture(:partial_duration).as(:duration, :unit => :msec)
    end

    # # Not parsed at the moment:
    # SQL (0.2ms) SET SQL_AUTO_IS_NULL=0
    # Query Load (0.4ms) SELECT `queries`.* FROM `queries`
    # Rendered collection (0.0ms)

    REQUEST_CATEGORIZER = lambda { |request| "#{request[:controller]}##{request[:action]}.#{request[:format]}" }

    report do |analyze|

      analyze.timespan
      analyze.hourly_spread
      analyze.daily_spread

      analyze.frequency :category => REQUEST_CATEGORIZER, :title => 'Most requested'
      analyze.frequency :method, :title => 'HTTP methods'
      analyze.frequency :status, :title => 'HTTP statuses returned'

      analyze.duration :duration, :category => REQUEST_CATEGORIZER, :title => "Request duration", :line_type => :completed
      analyze.duration :partial_duration, :category => :rendered_file, :title => 'Partials rendering time', :line_type => :rendered, :multiple => true
      analyze.duration :view, :category => REQUEST_CATEGORIZER, :title => "View rendering time", :line_type => :completed
      analyze.duration :db, :category => REQUEST_CATEGORIZER, :title => "Database time", :line_type => :completed

      analyze.frequency :category => REQUEST_CATEGORIZER, :title => 'Process blockers (> 1 sec duration)',
        :if => lambda { |request| request[:duration] && request[:duration] > 1.0 }

      analyze.frequency :category => lambda{|x| "[#{x[:missing_resource_method]}] #{x[:missing_resource]}"},
        :title => "Routing Errors", :if => lambda{ |request| !request[:missing_resource].nil? }
    end

    class Request < RequestLogAnalyzer::Request
      # Used to handle conversion of abbrev. month name to a digit
      MONTHS = %w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)

      def convert_timestamp(value, definition)
        # the time value can be in 2 formats:
        # - 2010-10-26 02:27:15 +0000 (ruby 1.9.2)
        # - Thu Oct 25 16:15:18 -0800 2010
        if value =~ /^#{CommonRegularExpressions::TIMESTAMP_PARTS['Y']}/
          value.gsub!(/\W/,'')
          value[0..13].to_i
        else
          value.gsub!(/\W/,'')
          time_as_str = value[-4..-1] # year
          # convert the month to a 2-digit representation
          month = MONTHS.index(value[3..5])+1
          month < 10 ? time_as_str << "0#{month}" : time_as_str << month.to_s

          time_as_str << value[6..13] # day of month + time
          time_as_str.to_i
        end

      end
    end

  end
end
