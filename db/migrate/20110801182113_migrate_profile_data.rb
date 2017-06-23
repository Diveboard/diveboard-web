class MigrateProfileData < ActiveRecord::Migration
  def self.up
    Dive.all.each do |dive|
    
    Dive.transaction do
      xml = UploadedProfile.new
      xml.data = dive.profile_data
      xml.source = "computed"
      xml.save
      dive.uploaded_profile_id = xml.id
      dive.uploaded_profile_index = 0
      dive.save

      uppercase_parser = Nokogiri::XML(Nokogiri::XML(dive.profile_data).serialize(:save_with =>0).to_s.upcase)

      uppercase_parser.xpath('//T').each { |time|
        sample = {}
        next_node = time.next_sibling
        sample["time"] = time.content.to_i
        sample["ascent_violation"] = "F"
        sample["deco_violation"] = "F"
        sample["gas_switch"] = "1.0"

        p = ProfileData.new
        p.seconds = sample["time"]
        p.dive_id = dive.id

        while !next_node.nil? && next_node.node_name != "T" do
          case next_node.node_name
          when "D" then
            p.depth = next_node.content.to_f
          when /TEMPERATURE/i
            p.current_water_temperature = next_node.content.to_f
          when /ALARM/i
            case next_node.content
            when /ASCENT/i then
              p.ascent_violation = true
            when /DECO/i then
              p.deco_start = true
            end
          end
          next_node = next_node.next_sibling
        end

        p.save
      }
    
    end
    end
  end

  def self.down
    execute "DELETE FROM profile_data"
    execute "DELETE FROM uploaded_profiles"
  end
end
