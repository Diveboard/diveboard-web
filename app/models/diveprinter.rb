require "prawn"
require "prawn/document"
require "prawn/measurement_extensions"
#require 'prawn/fast_png'
require 'open-uri'
require 'fileutils'
require 'yaml'
require 'stringex'
require 'validation_helper'
require 'delayed_job'




class Diveprinter
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming


  attr_accessor :diver, :dives, :initial_data


  class HighlightCallback
    def initialize(options)
      @color = options[:color]
      @document = options[:document]
      @box_w=options[:box_w] || 2

    end
    def render_behind(fragment)
      @document.transparent(0.2) {
        original_color = @document.fill_color
        @document.fill_color = @color
        @document.fill_rounded_rectangle([fragment.top_left[0]-@box_w,fragment.top_left[1]+@box_w], fragment.width+2*@box_w, fragment.height+1, 2)
        @document.fill_color = original_color
      }
    end
  end



  def initialize(attributes = {})
    @initial_data = nil
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def randomFileNameSuffix (numberOfRandomchars)
    s = ""
    numberOfRandomchars.times { s << (65 + rand(26))  }
    s
  end


  def generate_pdf_dives dives, userid, attributes={} #, y # resp, out
    ##v2 of the function with new layout by richard

    @page_width = attributes[:page_width] || 140.mm
    @page_height = attributes[:page_height] || 203.mm
    @cut_margins = attributes[:cut_margins] || 10.mm
    @pictures_pages = attributes[:pictures_pages] || 1
    @hole_offset = attributes[:hole_offset] || 17.mm
    @nohole_offset = attributes[:nohole_offset] || 7.mm
    @page_line_width = @page_width - @hole_offset - 4.mm
    @reverse = attributes[:reverse] || true

    hash=randomFileNameSuffix(10)
    file = File.new("/tmp/logbook"+hash+".pdf", "wb")


    bg_logo = "templates/db_logo_big2.png"
    bottom_logo = "templates/db_logo_small.png"
    @months=["Jan.", "Feb.", "Mar.", "Apr.","May ", "Jun.", "Jul.", "Aug", "Sep.", "Oct.", "Nov.", "Dec."]
    divescount=0



    pdf = Prawn::Document.new :page_size =>[@page_width+2*@cut_margins, @page_height+2*@cut_margins], :margin => @cut_margins
    ##PRINTING PDF
    pdf.font_families.update(
    "Futura" => {
      :normal => "#{Rails.root}/templates/fonts/futura_light.ttf",
      :bold => "#{Rails.root}/templates/fonts/futura_medium.ttf",
      :italic => "#{Rails.root}/templates/fonts/futura_lightoblique.ttf",
      :heavy =>  "#{Rails.root}/templates/fonts/futura_heavy.ttf"
    })
    pdf.font_families.update(
    "Futura_heavy" => {
          :normal => "#{Rails.root}/templates/fonts/futura_heavy.ttf",
          :bold => "#{Rails.root}/templates/fonts/futura_heavy.ttf",
          :italic => "#{Rails.root}/templates/fonts/futura_heavy.ttf",
          :heavy =>  "#{Rails.root}/templates/fonts/futura_heavy.ttf"
        })
    pdf.font "Futura"


    @user = User.find(userid)
    if @user.preferred_units["distance"]=="ft"
      graphunits = "i"
      @si_unit = false
    else
      graphunits = "m"
      @si_unit = true
    end
    Rails.logger.debug "User units : #{@user.preferred_units.to_s}"
    @ac = ApplicationController.new
    @ac.set_user @user
    pdf_cover_page pdf
    pdf_init_page pdf, :right if @reverse == true #we need the back of the cover page

    dives.each do |dive_id|
      pagescount = 0 # number of pages for dive
      @dive = Dive.find(dive_id)
      Rails.logger.debug "Printing pdf of dive #{dive_id}"
      Rails.logger.debug "Aacces to dive granted starting up "
      divescount +=1
      pdf_init_page pdf, :left
      pdf_header pdf
      pdf_diveinfo pdf
      if @current_orientation == :left && @reverse == true
        # we need an even number of pages for printing
        pdf_init_page pdf, :right
      end
    end
    pdf.render_file file.path
    ##TODO : raise an error if divescount still == 0

    ## Notify User
    Notification.create :user => @user, :about => @user, :kind => 'dives_printed', :param => "#{HtmlHelper.find_root_for @user}api/print_dives?hash=#{hash}"
  end
  handle_asynchronously :generate_pdf_dives



   ##HELPER METHODS
   def pdf_init_page p, position
     ## init page with holes at :left or :right (:position argument)
     @current_orientation = position
     Rails.logger.debug "creating a new page"
     p.start_new_page
     p.bounding_box [0, @page_height], :width => @page_width, :height => @page_height do
         p.line_width = 0.01
         p.stroke_color 30, 30, 30, 30 # CMYK
         p.dash(1); p.stroke_bounds; p.undash
         if position == :left
           p.stroke_line [10.mm, 31.mm], [12.mm, 31.mm]
           p.stroke_line [11.mm, 30.mm], [11.mm, 32.mm]
           p.stroke_line [10.mm, 101.mm], [12.mm, 101.mm]
           p.stroke_line [11.mm, 100.mm], [11.mm, 102.mm]
           p.stroke_line [10.mm, 171.mm], [12.mm, 171.mm]
           p.stroke_line [11.mm, 170.mm], [11.mm, 172.mm]
           @left_offset = @hole_offset ## hole margin
         elsif position == :right
           p.stroke_line [130.mm, 31.mm], [128.mm, 31.mm]
           p.stroke_line [129.mm, 30.mm], [129.mm, 32.mm]
           p.stroke_line [130.mm, 101.mm], [128.mm, 101.mm]
           p.stroke_line [129.mm, 100.mm], [129.mm, 102.mm]
           p.stroke_line [130.mm, 171.mm], [128.mm, 171.mm]
           p.stroke_line [129.mm, 170.mm], [129.mm, 172.mm]
           @left_offset =  @nohole_offset  ## no_hole_margin
         end
     end
     @top_position = 0.mm ## we will need to use that to knwo really where we are
   end

   def pdf_cover_page p
     p.move_down 90.mm
     p.text "#{@user.vanity_url}'s logbook",:align => :center, :size => 18, :style => :bold
     p.move_down 3.mm
     p.text "Generated: #{Date.today}",:align => :center, :size => 14, :style=> :italic
   end

   def pdf_header p
      p.image "public/img/pdf/logo-prawn.png", :at => [(104 + @left_offset), 199.mm], :width => 45.mm #15 is the image's width/2

      p.text_box @dive.fullpermalink(:canonical), :style => :italic, :size => 6, :align => :center, :at => [@left_offset, 191.mm], :width => @page_line_width, :font => "Helvetica"
      p.fill_color "333333"
      p.text_box "#{@months[@dive.time_in.month-1].upcase}#{@dive.time_in.day}", :at => [105.mm+@left_offset, 197.mm ], :width=> 25.mm, :align => :left, :size => 11
      p.text_box "#{@dive.time_in.year}", :at => [105.mm+@left_offset, 192.mm ], :width=> 25.mm, :align => :left, :size => 15
      e = Prawn::Text::Box.new( @dive.spot.name.upcase, :at => [@left_offset, 183.mm ], :width=>  @page_line_width, :align => :center, :size => 18, :document => p, :style => :bold)
      #dry.render(:dry_run => true)
      e.render
      if !@dive.number.nil?
        f = Prawn::Text::Box.new( "##{@dive.number}", :at => [@left_offset, 195.mm ], :width=>  @page_line_width, :align => :left, :size => 18, :document => p, :style => :bold)
        #dry.render(:dry_run => true)
        f.render
      end
      @top_position = 20.mm+e.height
      Rails.logger.debug "position #{@top_position}"

   end

   def pdf_diveinfo p
     ### prints the diveinfo and the map
     p.image "public/img/pdf/info-prawn.png", :at => [@left_offset, @page_height - @top_position-12], :width => 10
     p.text_box "DIVE INFO", :at => [@left_offset +15, @page_height - @top_position-5.mm], :size => 11, :style => :bold
     p.image "public/img/pdf/pin-prawn.png", :at => [@left_offset+@page_line_width/2, @page_height - @top_position-12], :width => 10
     p.text_box "SPOT LOCATION", :at => [@left_offset +15+@page_line_width/2, @page_height - @top_position-5.mm], :size => 11, :style => :bold



     ### DIVE INFO BOX
     p.bounding_box([@left_offset, @page_height - @top_position-10.mm], :width => @page_line_width/2-14, :background_color =>"000000") do

       lineh = 17
       p.move_down 10
       p.fill_color "000000"
       p.default_leading 3
       column_width = @page_line_width*0.3
       ##Line
       p.text "TIME IN:", :size => 8, :style => :bold, :indent_paragraphs => 10
       p.move_up lineh
       p.text "<font name='Futura_heavy'>#{@dive.time_in.strftime("%H:%M")}</font>", :size => 8, :indent_paragraphs => column_width, :inline_format => true

       ##Line
       p.text "DURATION:", :size => 8, :style => :bold, :indent_paragraphs => 10, :inline_format => true
       p.move_up lineh
       p.text "<font name='Futura_heavy'>#{@dive.duration} <font size='5'>MINS</font></font>", :size => 8, :indent_paragraphs => column_width, :inline_format => true

       if !@dive.temp_surface.blank? || !@dive.temp_bottom.blank?
         p.text "SURF./BOT. TEMP:", :size => 8, :style => :bold, :indent_paragraphs => 10, :inline_format => true
         p.move_up lineh
         temp_txt =""
         if @dive.temp_surface.blank? then temp_txt += "-" else temp_txt += "<font name='Futura_heavy'>#{@ac.unit_temp(@dive.temp_surface.to_f,true,1).gsub("&deg;","")}</font>" end
         temp_txt += " / "
         if @dive.temp_bottom.blank? then temp_txt += "-" else temp_txt += "<font name='Futura_heavy'>#{@ac.unit_temp(@dive.temp_bottom.to_f,true,1).gsub("&deg;","")}</font>" end
         p.text temp_txt, :size => 8, :indent_paragraphs => column_width, :inline_format => true
       end
       begin
         stops = JSON.parse(@dive.safetystops)
         if !stops.blank?
           p.text "SAFETY STOPS:", :size => 8, :style => :bold, :indent_paragraphs => 10, :inline_format => true
           p.move_up lineh
           stops.each do |s|
             p.text "<font name='Futura_heavy'>#{@ac.unit_distance(s[0].to_f,true,0)}-#{s[1].to_f.round(0).to_i}<font size='5'>MINS</font></font>", :size => 8, :indent_paragraphs => column_width, :inline_format => true
           end
         end
       rescue
         Rails.logger.debug "No Safety Stops"
       end
       if !@dive.water.blank?
         p.text "WATER:", :size => 8, :style => :bold, :indent_paragraphs => 10, :inline_format => true
         p.move_up lineh
         p.text "<font name='Futura_heavy'>#{@dive.water}</font>", :size => 8, :indent_paragraphs => column_width, :inline_format => true
       end
       if !@dive.current.blank?
         p.text "CURRENT:", :size => 8, :style => :bold, :indent_paragraphs => 10, :inline_format => true
         p.move_up lineh
         p.text "<font name='Futura_heavy'>#{@dive.current}</font>", :size => 8, :indent_paragraphs => column_width, :inline_format => true
       end
       if @dive.altitude && @dive.altitude > 0
         p.text "ALTITUDE:", :size => 8, :style => :bold, :indent_paragraphs => 10, :inline_format => true
         p.move_up lineh
         p.text "<font name='Futura_heavy'>#{@ac.unit_distance(@dive.altitude,true,0)}</font>", :size => 8, :indent_paragraphs => column_width, :inline_format => true
       end

       if !@dive.divetype.blank?
         type = ""
         @dive.divetype.each_with_index do |divetype,i|
           if i==0
             type+=divetype
           else
             type+=", #{divetype}"
           end
         end
         if @dive.divetype.length==1
           p.text "DIVE TYPE:", :size => 8, :style => :bold, :indent_paragraphs => 10, :inline_format => true
           p.move_up lineh
           p.text "#{type.downcase}", :size => 8, :indent_paragraphs => column_width, :inline_format => true, :style => :bold
         else
           p.text "DIVE TYPE:", :size => 8, :style => :bold, :indent_paragraphs => 10, :inline_format => true
           p.move_up lineh
           p.text "#{type.downcase}", :size => 8, :indent_paragraphs => 15.mm, :inline_format => true, :style => :bold, :align => :right
         end
       end

       begin
         if !@dive.diveshop["name"].blank?
           p.text "DIVE SHOP:", :size => 8, :style => :bold, :indent_paragraphs => 10, :inline_format => true
           p.move_up lineh
           p.text "#{@dive.diveshop["name"]}", :size => 8, :indent_paragraphs => 15.mm, :inline_format => true, :style => :bold, :align => :right
         end
       rescue
         Rails.logger.debug "No diveshop for dive #{@dive.id}"
       end

       buddies = []
       if !@dive.guide.blank?
         buddies.push("<font name='Futura_heavy'>#{@dive.guide.titleize}</font>") rescue nil
       end
       buddies += (@dive.buddies.map(&:nickname).reject{|e| e.nil?} .map(&:titleize))
       if buddies.count > 0 then
         p.text "BUDDIES:", :size => 8, :style => :bold, :indent_paragraphs => 10, :inline_format => true
         p.move_up lineh
         p.text buddies.join(", "), :size => 8, :indent_paragraphs => 15.mm, :inline_format => true, :style => :bold, :align => :right
       end

       p.transparent(0.2) {
         #p.stroke_bounds
         p.fill_color "AAAAAA"
         p.fill_rectangle p.bounds.top_left, (p.bounds.width+3), p.bounds.height
         @dive_info_height = p.bounds.height ## we'll need that lated
       }
     end


     ## SPOT LOCATION BOX

     spot_s = ""
     if !@dive.spot.country.nil? && @dive.spot.country.id != 1
       spot_s += begin @dive.spot.country.cname.upcase rescue "" end
     end
     if !@dive.spot.location.nil? && @dive.spot.location.id != 1
       if spot_s != "" then spot_s += " - " end
       spot_s += begin @dive.spot.location.name.titleize rescue "" end
     end
     if !@dive.spot.region.nil? && @dive.spot.region.id != 1
       if spot_s != "" then spot_s += " - " end
       spot_s += begin @dive.spot.region.name.titleize rescue "" end
     end

     e = Prawn::Text::Box.new( spot_s, :at => [(@left_offset + @page_line_width/2), (@page_height - @top_position-10.mm)], :width=>  (@page_line_width/2 -10), :align => :left, :size => 8, :document => p, :style => :bold)
     e.render(:dry_run => true)


     map_image = Tempfile.new(['map', '.jpg'])
     map_w = 250
     map_h = 250/(@page_line_width/2-10)*(@dive_info_height - e.height - 2 )
     zoomfix = (@dive.spot.zoom) -2
     if zoomfix < 1 then
       zoomfix = 1
     end
     
     ## Keep maps as http not https or HTTP.get will fail
     ## todo: support https
     url = "https://maps.google.com/maps/api/staticmap?center=#{@dive.spot.lat.to_f},#{@dive.spot.long.to_f}&zoom=#{zoomfix}&size=#{map_w.to_i}x#{map_h.to_i}&maptype=terrain&markers=icon:https://www.diveboard.com/img/marker.png|#{@dive.spot.lat.to_f},#{@dive.spot.long.to_f}&sensor=false&format=jpg&key=#{GOOGLE_MAPS_API}"
     Rails.logger.debug "Getting map at url #{url}"
     #File.open(map_image,"wb"){|f| f.write(Net::HTTP.get URI.parse(URI.encode url))}
     p.image open(URI.encode url), :at => [(@left_offset + @page_line_width/2), (@page_height - @top_position-10.mm)], :width => (@page_line_width/2-10), :height => (@dive_info_height-e.height)
     #map_image.unlink

     f = Prawn::Text::Box.new( spot_s, :at => [(@left_offset + @page_line_width/2), (@page_height - @top_position-10.mm - @dive_info_height + e.height - 2)], :width=>  (@page_line_width/2 -10), :align => :left, :size => 8, :document => p, :style => :bold)
     f.render()

     ##SECTION DONE

     @top_position = @top_position+10.mm + @dive_info_height
     Rails.logger.debug "after dive infos top position is #{@top_position}"

     ## DIVE PROFILE BOX

     check_space_or_newpage p, 25
      p.image "public/img/pdf/profile.png", :at => [@left_offset, @page_height - @top_position-13], :width => 10, :height => 9
      p.text_box "DIVE PROFILE", :at => [@left_offset +15, @page_height - @top_position-5.mm], :size => 11, :style => :bold
      @top_position = @top_position + 10

      if @user.preferred_units["distance"]=="ft"
        graphunits = "i"
      else
        graphunits = "m"
      end
      Rails.logger.debug "getting graph at : #{@dive.fullpermalink(:locale)}/profile.png?g=pdf_print&u=#{graphunits}&locale=#{I18n.locale}"
      #File.open(profile_image,"wb"){|f| f.write(Net::HTTP.get URI.parse("#{@dive.fullpermalink(:locale)}/profile.png?g=pdf_print&u=#{graphunits}&locale=#{I18n.locale}"))}
      profile = p.image open(URI.parse("#{@dive.fullpermalink(:locale)}/profile.png?u=#{graphunits}&locale=#{I18n.locale}")), :at => [@left_offset-10, @page_height - @top_position-10], :width => @page_line_width+5 rescue nil
      #profile_image.unlink

     ##END OF DIVE PROFILE BOX
     @top_position  = @top_position + profile.scaled_height unless profile.nil?
     Rails.logger.debug "after profile top position is #{@top_position}"

     ## DIVE NOTES BOX

     if !@dive.notes.blank?
       check_space_or_newpage p, 25
       e = Prawn::Text::Box.new( @dive.notes, :at => [@left_offset, (@page_height - @top_position-15.mm)], :width=>  (@page_line_width -10), :align => :justify, :size => 8, :document => p, :style => :bold)
       e.render(:dry_run => true)
       Rails.logger.debug "notes height will be #{e.height}"

       p.image "public/img/pdf/notes.png", :at => [@left_offset, @page_height - @top_position-17], :width => 10, :height => 10
       p.text_box "DIVE NOTES", :at => [@left_offset +15, @page_height - @top_position-18], :size => 11, :style => :bold
       e = Prawn::Text::Box.new( @dive.notes, :at => [@left_offset, (@page_height - @top_position-32)], :width=>  (@page_line_width -10), :align => :justify, :size => 8, :document => p, :style => :bold, :overflow => :truncate)
       remaining_text = e.render()
       @top_position = @top_position +32+ e.height
       if !remaining_text.blank?
         ## we need a new page !
         if @reverse && @current_orientation == :left
           pdf_init_page p, :right
         else
           pdf_init_page p, :left
         end
         f = Prawn::Text::Box.new( remaining_text, :at => [@left_offset, @page_height-5], :width=>  (@page_line_width -10 ), :align => :justify, :size => 8, :document => p, :style => :bold)
         f.render()
         @top_position = @top_position +5+ f.height
       end
     end
     ## SPECIES SPOTTED LIST
     spaces = 3

     if !@dive.eolcnames.blank? || !@dive.eolsnames.blank?
       check_space_or_newpage p, 25


       p.image "public/img/pdf/species.png", :at => [@left_offset, @page_height - @top_position-17], :width => 10, :height => 10
        p.text_box "SPECIES SPOTTED", :at => [@left_offset +15, @page_height - @top_position-18], :size => 11, :style => :bold
       highlight = HighlightCallback.new(:color => 'aaaaaa', :document => p)


       species_spotted = species_array @dive, highlight
       e = Prawn::Text::Formatted::Box.new(species_spotted, :size => 9, :width =>  (@page_line_width -10), :overflow => :truncate, :at => [@left_offset, @page_height - @top_position-32], :document => p )
       remaining_text = e.render

       @top_position = @top_position +32+ e.height

       if !remaining_text.blank?
          ## we need a new page !
          if @reverse && @current_orientation == :left
            pdf_init_page p, :right
          else
            pdf_init_page p, :left
          end
          f = Prawn::Text::Formatted::Box.new(remaining_text, :size => 9, :width =>  (@page_line_width -10), :overflow => :truncate, :at => [@left_offset, @page_height-5], :document => p )
          f.render
          @top_position = @top_position +5+ f.height
        end
        Rails.logger.debug "after species top position is #{@top_position}"
        Rails.logger.debug "remains : #{@page_height - @top_position}"

     end

     #### GEAR SECTION
     if !@dive.gears.blank? || !@dive.tanks.blank? || !@dive.weights.blank?
       check_space_or_newpage p, 25

       p.image "public/img/pdf/gear-prawn.png", :at => [@left_offset, @page_height - @top_position-17], :width => 10, :height => 10
         p.text_box "GEAR USED", :at => [@left_offset +15, @page_height - @top_position-18], :size => 11, :style => :bold
        highlight = HighlightCallback.new(:color => 'aaaaaa', :document => p)

        gear_list = @dive.gears.sort! { |a,b| a.category.downcase <=> b.category.downcase }

        gear_used = []
        current_category = ""
        gear_list.each do |gear|
          if !gear_used.blank?
            gear_used << {:text=>" "*spaces}
          end
          if current_category != gear.category.downcase
            current_category = gear.category.downcase
             gear_used << {:text=> gear.category.upcase, :size => 8, :font => 'Futura_heavy'}
             gear_used << {:text=>" "*spaces}
          end
          gear_data =""
          gear_data += "#{gear.manufacturer}"
          if gear_data != "" && !gear.model.blank? then gear_data += " " end
          gear_data += "#{gear.model}"
          gear_used << {:text=> gear_data, :callback => highlight}
        end
        if !@dive.tanks.blank?
          if !gear_used.blank?
            gear_used << {:text=>"\n"}
          end
          gear_used << {:text=> "TANKS", :size => 8, :font => 'Futura_heavy'}
          gear_used << {:text=>" "*spaces}
          @dive.tanks.each do |tk|

            tk_info = "#{tk.material} "
            if tk.multitank>1 then tk_info += "#{tk.multitank}x" end
            tk_info +="#{tk.volume_n(@si_unit).to_i}"
            if @si_unit then tk_info += "L" else tk_info += "cuft" end
            tk_info += " #{tk.gas}"
            if tk.gas == "custom"
              tk_info += " O2:#{tk.o2}%, N2:#{tk.n2}%, He:#{tk.he}%"
            end
            tk_info += " #{tk.p_start_n(@si_unit)} > #{tk.p_end_n(@si_unit)}"
            if @si_unit then tk_info += "bar" else tk_info += "psi" end
            gear_used << {:text=> tk_info, :callback => highlight}
        end
      end

      if !@dive.weights.blank?
         if !gear_used.blank?
           gear_used << {:text=>"\n"}
         end
         gear_used << {:text=> "WEIGHTS", :size => 8, :font => 'Futura_heavy'}
         gear_used << {:text=>" "*spaces}
         gear_used << {:text=> "#{@ac.unit_weight(@dive.weights,true,0)}", :callback => highlight}
       end

      e = Prawn::Text::Formatted::Box.new(gear_used, :size => 9, :width =>  (@page_line_width -10), :overflow => :truncate, :at => [@left_offset, @page_height - @top_position-32], :document => p )
      remaining_text = e.render

      @top_position = @top_position +32+ e.height

      if !remaining_text.blank?
         ## we need a new page !
         if @reverse && @current_orientation == :left
           pdf_init_page p, :right
         else
           pdf_init_page p, :left
         end
         f = Prawn::Text::Formatted::Box.new(remaining_text, :size => 9, :width =>  (@page_line_width -10), :overflow => :truncate, :at => [@left_offset, @page_height-5], :document => p )
         f.render
         @top_position = @top_position +5+ f.height
       end
       Rails.logger.debug "after gear top position is #{@top_position}"
     end
     ## GEAR DONE

     ##PICTURES !!!

     pics_array = @dive.pictures
     pics_lines = (pics_array.length/2).to_i + (pics_array.length % 2)
     current_pic_line = 0
     pic_pages = 0
     pics_width_with_margin = @page_line_width / 2
     pics_width_without_margin = pics_width_with_margin-10
     pics_height_without_margin = pics_width_without_margin*3/4 #(@page_height -20)/4
     line_space = 20
     pics_height_with_margin = pics_height_without_margin+line_space
     highlight = HighlightCallback.new(:color => 'aaaaaa', :document => p, :box_w => 1)
     pictspace = true


      if check_space_or_newpage(p,pics_height_with_margin+10, true)
         Rails.logger.debug "need a new pic page"
         check_space_or_newpage(p,pics_height_with_margin+10)
         @top_position += 10
       end


     if @pictures_pages != 0 && !@dive.pictures.blank? && pictspace


        p.image "public/img/pdf/pict-prawn.png", :at => [@left_offset, @page_height - @top_position-17.5], :width => 10, :height => 10
        p.text_box "PICTURES", :at => [@left_offset +15, @page_height - @top_position-18], :size => 11, :style => :bold

        @top_position += 37

        begin

          if check_space_or_newpage(p,pics_height_with_margin-10, true)
            Rails.logger.debug "need a new pic page"
            pic_pages += 1

            if pic_pages < @pictures_pages || @pictures_pages == -1
              check_space_or_newpage(p,pics_height_with_margin-10)
              @top_position += 10
            else
              #that's enough pictures
              break
            end
          end

          Rails.logger.debug "printing picture line #{current_pic_line}"
          begin
            image = p.image open(pics_array[2*current_pic_line].medium), :fit => [pics_width_without_margin, pics_height_without_margin], :at => [@left_offset+5, @page_height - @top_position]
            add_margin = pics_height_without_margin -image.scaled_height-2
          rescue
            Rails.logger.debug "Could not retrive picture #{pics_array[2*current_pic_line].id}"
            add_margin = pics_height_without_margin/2
          end
          if !pics_array[2*current_pic_line].notes.blank?
            notes = [
              {:text => pics_array[2*current_pic_line].notes, :styles => [:italic]},
              {:text => " "*3}
            ]
          else
            notes = []
          end
          species_spotted = notes + species_array(pics_array[2*current_pic_line] , highlight, 2)
          Prawn::Text::Formatted::Box.new(species_spotted, :size => 8, :height=> line_space+add_margin, :width =>  pics_width_without_margin , :overflow => :shrink_to_fit, :at => [@left_offset+5, @page_height - @top_position-pics_height_without_margin+add_margin], :document => p ).render

          if pics_array[2*current_pic_line+1]
              begin
                image = p.image open(pics_array[2*current_pic_line+1].medium), :fit => [pics_width_without_margin, pics_height_without_margin], :at => [@left_offset+pics_width_with_margin+5, @page_height - @top_position]
             add_margin = pics_height_without_margin -image.scaled_height-2
            rescue
              Rails.logger.debug "Could not retrive picture #{pics_array[2*current_pic_line].id}"
              add_margin = pics_height_without_margin/2
            end
             if !pics_array[2*current_pic_line+1].notes.blank?
               notes = [
                 {:text => pics_array[2*current_pic_line+1].notes, :styles => [:italic]},
                 {:text => " "*3}
               ]
             else
               notes = []
             end
             species_spotted = notes + species_array(pics_array[2*current_pic_line+1] , highlight, 2)
             Prawn::Text::Formatted::Box.new(species_spotted, :size => 8, :height=> line_space+add_margin, :width =>  pics_width_with_margin-10 , :overflow => :shrink_to_fit, :at => [@left_offset+pics_width_with_margin+5, @page_height - @top_position-pics_height_without_margin+add_margin], :document => p ).render
          end


          current_pic_line += 1
          @top_position += pics_height_with_margin
        end while current_pic_line < pics_lines
      end

   end

   def check_space_or_newpage p, space, dry=false
     if @page_height - @top_position -17 < space
       ## we need a new page !
       if !dry
         if @reverse && @current_orientation == :left
           pdf_init_page p, :right
         else
           pdf_init_page p, :left
         end
       end
       return true
     end
     return false
   end

   def species_array obj, callback, spaces=3
     species_spotted = []
     obj.eolcnames.each do |species|
       if !species_spotted.blank?
         species_spotted << {:text=>" "*spaces}
       end
       species_spotted << {:text=>species.cname.titleize, :callback => callback}
     end
     obj.eolsnames.each do |species|
       if !species_spotted.blank?
         species_spotted << {:text=>" "*spaces}
       end
       species_spotted << {:text=>species.sname.titleize, :callback => callback}
     end
     return species_spotted
   end
   ##END HELPERS
end
