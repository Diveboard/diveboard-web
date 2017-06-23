require 'sanitize'
require 'css_parser'

module HtmlHelper

  def HtmlHelper.sanitize(text, options = {})


    config = {
      :elements => %w(div span img a abbr b blockquote br cite code dd dfn dl dt em h1 h2 h3 h4 h5 h6 i kbd li mark ol p pre q s samp small strike strong sub sup time u ul var table tbody tr td),
      :attributes => {
        'a' => %w(href),
        'div' => %w(style),
        'span' => %w(style),
        'img' => %w(src alt style),
        'table' => %w(rules style),
        'tbody' => %w(rules style),
        'tr' => %w(rules style),
        'td' => %w(rules style),
      },
      :filter_style => {
        'text-align' => %w(left right center),
        'float' => %w(left right),
        'clear' => %w(left right both),
        'width' => /^[0-9]*px$/,
        'height' => /^[0-9]*px$/,
        'text-decoration' => %w(underline),
        'border' => /^.+$/
      },
      :add_attributes => {
        'a' => {'rel' => 'nofollow', 'target' => '_blank'}
      },
      :protocols => {
        'a' => {'href' => ['http', 'https', 'mailto', :relative]},
        'img' => {'src' => ['http', 'https', :relative]}
      },

      :transformers => [Filters.method(:filter_diveboard_inner_links), Filters.method(:filter_style), Filters.method(:filter_diveboard_img)] #, Filters.method(:filter_allow_youtube) ]

      }
    if options[:shift_headings].is_a?(Fixnum) then
      options[:shift_headings].times do
        config[:transformers].push Filters.method(:shift_headings)
      end
    end

    if options[:wordpress_article]
      config[:attributes]["a"].push "class"
      config[:attributes]["img"].push "class"
      config[:transformers].push Filters.method(:filter_class_wordpress_article)
    end

    if options[:blog_article]
      #enable plenty kind of external embeds
      config[:elements].push "iframe"
      config[:attributes]["iframe"] = %w(src width height frameborder allowfullcreen divbeoard_thumb)
      config[:elements].push "object"
      config[:attributes]["object"] = %w(allowfullsecreen data height width name id seamlesstabbing type)
      config[:elements].push "param"
      config[:attributes]["param"] = %w(name value)
      config[:add_attributes] = {'a' => {'target' => '_blank'}}
      config[:attributes]["a"] = %w(href rel class)
      config[:transformers].push Filters.method(:filter_outbound_links)

    end

    Sanitize.clean(text, config)

  end


  module Filters

    def Filters.filter_diveboard_inner_links(env)
      begin
        node      = env[:node]
        node_name = env[:node_name]
        return unless node_name.match(/a/i)
        return if node['href'].blank?
        if m=node['href'].match(/spot\:\/\/(.+)$/)
          p = Spot.fromshake(m[1])
        elsif m=node['href'].match(/location\:\/\/(.+)$/)
          p = Location.fromshake(m[1])
        elsif m=node['href'].match(/region\:\/\/(.+)$/)
          p = Region.fromshake(m[1])
        elsif m=node['href'].match(/country\:\/\/(.+)$/)
          p = Country.fromshake(m[1])
        elsif m=node['href'].match(/dive\:\/\/(.+)$/)
          p = Dive.fromshake(m[1])
        elsif m=node['href'].match(/fish\:\/\/(.+)$/)
          p = Eolsname.fromshake(m[1])
        else
          return
        end
        Rails.logger.debug "Replacing #{node['href']} by #{p.fullpermalink(:locale)}"
        node['href'] = p.fullpermalink(:locale)
      rescue
        Rails.logger.debug $!.message
      end
    end

    def Filters.filter_diveboard_img(env)
      begin
        node      = env[:node]
        node_name = env[:node_name]
        return unless node_name.match(/img/i)
        return if node['src'].blank?
        return unless (m=node['src'].match(/\/api\/picture\/get\/([a-zA-Z0-9]+)/))

        p = Picture.fromshake(m[1])
        Rails.logger.debug "Replacing #{node['src']} by #{p.original}"
        node['src'] = p.original
      rescue
        Rails.logger.debug $!.message
      end
    end

    def Filters.filter_outbound_links(env)
      begin
        node      = env[:node]
        node_name = env[:node_name]
        return unless node_name.match(/a/i)
        if node['href'] =~ /diveboard.com/i
          node['rel'] =""
        else
          Rails.logger.debug "#{node['href']} is external"
          node['rel']="nofollow"
        end
      rescue
        Rails.logger.debug $!.message
      end
    end


    def Filters.filter_class_wordpress_article(env)
      authorized_tags = %w(alignleft aligncenter alignright)
      begin
        node      = env[:node]
        node_name = env[:node_name]
        return unless node_name.match(/img/i) || node_name.match(/a/i)
        return if node['class'].blank?
        Rails.logger.debug "Keeping class for blog tags"
        cl= ""
        node['class'].split(" ").each do |c|
          if authorized_tags.include? c
            cl = cl + " "+c
            Rails.logger.debug "Keeping class for blog tags " + c
          end
        end
        if cl.blank?
          Rails.logger.debug "Removing attributes: "+node['class']
          node.remove_attribute('class')
        else
          Rails.logger.debug "Updating blog tags " + cl
          node['class'] = cl
        end
      rescue
      end
    end

    def Filters.filter_style(env)
      begin
        node      = env[:node]
        node_name = env[:node_name]
        return if node['style'].blank?

        style = node['style']
        new_style = ''
        properties_whitelist = env[:config][:filter_style]
        style.split(/ *; */).each do |param|
          key = param.split(/ *: */)[0].strip
          val = param.split(/ *: */)[1].strip
          next unless properties_whitelist.include? key
          filter = properties_whitelist[key]
          keep_style = false
          keep_style = true if filter == :all
          keep_style = true if filter.is_a?(Regexp) && filter.match(val)
          keep_style = true if filter.is_a?(Array) && filter.include?(val)
          new_style += "#{key}:#{val};" if keep_style
        end
        node['style'] = new_style
        node.remove_attribute('style') if new_style.blank?
      rescue
      end
    end

    def Filters.filter_allow_youtube(env)
      node      = env[:node]
      node_name = env[:node_name]

      # Don't continue if this node is already whitelisted or is not an element.
      return if env[:is_whitelisted] || !node.element?

      # Don't continue unless the node is an iframe.
      return unless node_name == 'iframe'

      # Verify that the video URL is actually a valid YouTube video URL.
      return unless node['src'] =~ /\Ahttps?:\/\/(?:www\.)?youtube(?:-nocookie)?\.com\//

      # We're now certain that this is a YouTube embed, but we still need to run
      # it through a special Sanitize step to ensure that no unwanted elements or
      # attributes that don't belong in a YouTube embed can sneak in.
      Sanitize.clean_node!(node, {
        :elements => %w[iframe],

        :attributes => {
          'iframe'  => %w[allowfullscreen frameborder height src width]
        }
      })

      # Now that we're sure that this is a valid YouTube embed and that there are
      # no unwanted elements or attributes hidden inside it, we can tell Sanitize
      # to whitelist the current node.
      {:node_whitelist => [node]}
    end

    def Filters.shift_headings(env)
      node      = env[:node]
      node_name = env[:node_name]
      case node_name
        when 'h1'
          node.node_name = 'h2'
        when 'h2'
          node.node_name = 'h3'
        when 'h3'
          node.node_name = 'h4'
        when 'h4'
          node.node_name = 'h5'
        when 'h5'
          node.node_name = 'h6'
        when 'h6'
          node.node_name = 'h6'
      end
    end
  end


  def HtmlHelper.set_ssl(val)
    @@ssl = val
  end

  def HtmlHelper.lbroot(path = nil)
    @@ssl ||= false

    if path.blank? then
      return HtmlHelper.find_lbroot_for(path)
    elsif @@ssl || path.match(/^https?:\/\//) then
      return path
    else
      return HtmlHelper.find_lbroot_for(path)+path.gsub(/^\//, "")
    end
    HtmlHelper.find_lbroot_for(path)+path
  end

  def HtmlHelper.find_lbroot_for path=nil
    @@ssl ||= false
    if path.blank? then
      begin
        r = Rails.configuration.balancing_roots[(rand*Rails.configuration.balancing_roots.length).floor]
        return ROOT_URL if r.blank?
        return r
      rescue
        return ROOT_URL
      end
    elsif @@ssl || path.match(/^https?:\/\//) then
      return nil
    else
      begin
        rnd = Random.new(Zlib.crc32(path))
        r = Rails.configuration.balancing_roots[rnd.rand(Rails.configuration.balancing_roots.length)]
        return ROOT_URL if r.blank?
        return r
      rescue
        return ROOT_URL
      end
    end
  end


  def HtmlHelper.find_root_for option=nil
    option = option.preferred_locale if option.is_a? User
    option = :locale if option.nil?
    option = I18n.locale if option == :locale
    option = :default if option == I18n.default_locale

    if option.is_a? String then
      return option+"/" unless option[-1] == "/"
      return option
    elsif Rails.configuration.i18n.available_locales.include?(option) then
      return LOCALE_ROOT_URL % {locale: option}
    elsif option == :default or option == :canonical then
      return ROOT_URL
    else
      Rails.logger.warn "Unknown option for find_root_for: #{option}"
      return ROOT_URL if I18n.locale == I18n.default_locale
      return LOCALE_ROOT_URL % {locale: I18n.locale}
    end
  end

  def HtmlHelper.find_hostname_for option=nil
    URI.parse(HtmlHelper.find_root_for option).hostname
  end

#####
##### THIS CLASS COMES FROM the Roadie GEM (MIT LICENSE)
#####


  class StyleDeclaration
    include Comparable
    attr_reader :property, :value, :important, :specificity

    def initialize(property, value, important, specificity)
      @property = property
      @value = value
      @important = important
      @specificity = specificity
    end

    def important?
      @important
    end

    def <=>(other)
      if important == other.important
        specificity <=> other.specificity
      else
        important ? 1 : -1
      end
    end

    def to_s
      [property, value].join(':')
    end

    def inspect
      extra = [important ? '!important' : nil, specificity].compact
      "#{to_s} (#{extra.join(' , ')})"
    end
  end


# This class is the core of Roadie as it does all the actual work. You just give it
# the CSS rules, the HTML and the url_options for rewriting URLs and let it go on
# doing all the heavy lifting and building.
  class Inliner
    # Regexp matching all the url() declarations in CSS
    #
    # It matches without any quotes and with both single and double quotes
    # inside the parenthesis. There's much room for improvement, of course.
    CSS_URL_REGEXP = %r{
      url\(
        (["']?)
        (
          [^(]*            # Text leading up to before opening parens
          (?:\([^)]*\))*   # Texts containing parens pairs
          [^(]+            # Texts without parens - required
        )
        \1                 # Closing quote
      \)
    }x

    # Initialize a new Inliner with the given Provider, CSS targets, HTML, and `url_options`.
    #
    # @param [AssetProvider] assets
    # @param [Array] targets List of CSS files to load via the provider
    # @param [String] html
    # @param [Hash] url_options Supported keys: +:host+, +:port+, +:protocol+
    def initialize(html, with_body, url_options, css)
  #    @assets = assets
  #    @css = assets.all(targets)
      if css then
        @css = css.map do |file|
          File.read(file)
        end.join("\n")
      end
      @with_body = with_body
      @html = html
      @inline_css = []
      @url_options = url_options

      if url_options and url_options[:asset_path_prefix]
        raise DBArgumentError.new "The asset_path_prefix URL option is not working anymore. You need to add the following configuration to your application.rb:\n" +
                             "    config.roadie.provider = AssetPipelineProvider.new(_path_)\n" +
                             "Note that the prefix \"/assets\" is the default one, so you do not need to configure anything in that case.", path: url_options[:asset_path_prefix].inspect
      end
    end

    # Start the inlining and return the final HTML output
    # @return [String]
    def execute
      adjust_html do |document|
        @document = document
        add_missing_structure
  #      extract_link_elements
        extract_inline_style_elements
        inline_css_rules
        make_image_urls_absolute
        make_style_urls_absolute
        @document = nil
      end
    end

    private
      attr_reader :css, :html, :url_options, :document, :with_body
  #    attr_reader :css, :html, :assets, :url_options, :document

      def inline_css
        @inline_css.join("\n")
      end

      def parsed_css
        ::CssParser::Parser.new.tap do |parser|
          parser.add_block! clean_css(css) if css
          parser.add_block! clean_css(inline_css)
        end
      end

      def adjust_html
        d=Nokogiri::HTML.parse(html).tap do |document|
          yield document
        end
        if with_body then
          d.dup.to_html
        else
          d.dup.at("html > body").children.map(&:to_html).join("")
        end
      end

      def add_missing_structure
        html_node = document.at_css('html')
        html_node['xmlns'] ||= 'http://www.w3.org/1999/xhtml'

        if document.at_css('html > head').present?
          head = document.at_css('html > head')
        else
          head = Nokogiri::XML::Node.new('head', document)
          document.at_css('html').children.before(head)
        end

        # This is handled automatically by Nokogiri in Ruby 1.9, IF charset of string != utf-8
        # We want UTF-8 to be specified as well, so we still do this.
        unless document.at_css('html > head > meta[http-equiv=Content-Type]')
          meta = Nokogiri::XML::Node.new('meta', document)
          meta['http-equiv'] = 'Content-Type'
          meta['content'] = 'text/html; charset=UTF-8'
          head.add_child(meta)
        end
      end

  #    def extract_link_elements
  #      all_link_elements_to_be_inlined_with_url.each do |link, url|
  #        asset = assets.find(url.path)
  #        @inline_css << asset.to_s
  #        link.remove
  #      end
  #    end

      def extract_inline_style_elements
        document.css("style").each do |style|
          next if style['media'] == 'print' or style['data-immutable']
          @inline_css << style.content
          style.remove
        end
      end

      def inline_css_rules
        elements_with_declarations.each do |element, declarations|
          ordered_declarations = []
          seen_properties = Set.new
          declarations.sort.reverse_each do |declaration|
            next if seen_properties.include?(declaration.property)
            ordered_declarations.unshift(declaration)
            seen_properties << declaration.property
          end

          rules_string = ordered_declarations.map { |declaration| declaration.to_s }.join(';')
          element['style'] = [rules_string, element['style']].compact.join(';')
        end
      end

      def elements_with_declarations
        Hash.new { |hash, key| hash[key] = [] }.tap do |element_declarations|
          parsed_css.each_rule_set do |rule_set|
            each_selector_without_pseudo(rule_set) do |selector, specificity|
              each_element_in_selector(selector) do |element|
                style_declarations_in_rule_set(specificity, rule_set) do |declaration|
                  element_declarations[element] << declaration
                end
              end
            end
          end
        end
      end

      def each_selector_without_pseudo(rules)
        rules.selectors.reject { |selector| selector.include?(':') or selector.starts_with?('@') }.each do |selector|
          yield selector, ::CssParser.calculate_specificity(selector)
        end
      end

      def each_element_in_selector(selector)
        document.css(selector.strip).each do |element|
          yield element
        end
      end

      def style_declarations_in_rule_set(specificity, rule_set)
        rule_set.each_declaration do |property, value, important|
          yield StyleDeclaration.new(property, value, important, specificity)
        end
      end

      def make_image_urls_absolute
        document.css('img').each do |img|
          img['src'] = ensure_absolute_url(img['src']) if img['src']
        end
      end

      def make_style_urls_absolute
        document.css('*[style]').each do |element|
          styling = element['style']
          element['style'] = styling.gsub(CSS_URL_REGEXP) { "url(#{$1}#{ensure_absolute_url($2, '/stylesheets')}#{$1})" }
        end
      end

      def ensure_absolute_url(url, base_path = nil)
        base, uri = absolute_url_base(base_path), URI.parse(url)
        if uri.relative? and base
          base.merge(uri).to_s
        else
          uri.to_s
        end
      rescue URI::InvalidURIError
        return url
      end

      def absolute_url_base(base_path)
        return nil unless url_options
        port = url_options[:port]
        URI::Generic.build({
          :scheme => url_options[:protocol] || 'http',
          :host => url_options[:host],
          :port => (port ? port.to_i : nil),
          :path => base_path
        })
      end

      def all_link_elements_with_url
        document.css("link[rel=stylesheet]").map { |link| [link, URI.parse(link['href'])] }
      end

      def all_link_elements_to_be_inlined_with_url
        all_link_elements_with_url.reject do |link, url|
          absolute_path_url = (url.host or url.path.nil?)
          blacklisted_element = (link['media'] == 'print' or link['data-immutable'])

          absolute_path_url or blacklisted_element
        end
      end

      CLEANING_MATCHER = /
        (^\s*             # Beginning-of-lines matches
          (<!\[CDATA\[)|
          (<!--+)
        )|(               # End-of-line matches
          (--+>)|
          (\]\]>)
        $)
      /x.freeze

      def clean_css(css)
        css.gsub(CLEANING_MATCHER, '')
      end
  end

  class Tracker

    # Regexp matching all the url() declarations in CSS
    #
    # It matches without any quotes and with both single and double quotes
    # inside the parenthesis. There's much room for improvement, of course.
    CSS_URL_REGEXP = %r{
      url\(
        (["']?)
        (
          [^(]*            # Text leading up to before opening parens
          (?:\([^)]*\))*   # Texts containing parens pairs
          [^(]+            # Texts without parens - required
        )
        \1                 # Closing quote
      \)
    }x

    def initialize (html, with_body, medium, tracker_name, tracker_id, user_shaken_id)
      @html = html
      @with_body = with_body
      @tracker_name = tracker_name
      @tracker_id = tracker_id
      @user_shaken_id = user_shaken_id
      @additional_tag = "utm_source=#{tracker_name}&utm_medium=#{medium}&utm_campaign=#{tracker_name}_#{tracker_id}&source=#{tracker_name}&source_id=#{tracker_id}&user_id=#{user_shaken_id||"null"}"
    end
    def execute
      adjust_html do |document|
        document.css("a").each do |tag|
          tag["href"] = update_url tag["href"] unless tag["href"].blank?
        end
        document.css("img").each do |tag|
          tag["src"] = update_url tag["src"] unless tag["src"].blank?
        end
        document.css('*[style]').each do |element|
          styling = element['style']
          element['style'] = styling.gsub(CSS_URL_REGEXP) { "url(#{$1}#{ensure_absolute_url($2, '/stylesheets')}#{$1})" }
        end
      end
    end
    private
    def update_url url
      if url.match(/\.diveboard\.com/)
        if url.match(/\?/)
          return url + "&#{@additional_tag}"
        else
          return url + "?#{@additional_tag}"
        end
      else
        return url
      end
    end
    def adjust_html
      d=Nokogiri::HTML.parse(@html).tap do |document|
        yield document
      end
      if @with_body then
        d.dup.to_html
      else
        d.dup.at("html > body").children.map(&:to_html).join("")
      end
    end
    def ensure_absolute_url(url, base_path = nil)
      base, uri = absolute_url_base(base_path), URI.parse(url)
      if uri.relative? and base
        update_url base.merge(uri).to_s
      else
        update_url uri.to_s
      end
    rescue URI::InvalidURIError
      return update_url url
    end

    def absolute_url_base(base_path)
      url_options = {}
      return nil unless url_options
      port = url_options[:port]
      URI::Generic.build({
        :scheme => url_options[:protocol] || 'http',
        :host => url_options[:host],
        :port => (port ? port.to_i : nil),
        :path => base_path
      })
    end
  end

end
