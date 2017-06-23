require "iconv"
require 'cgi'

counter = 1

file = File.new("script/gbif_taxo_db_full_03_2011.txt","r")
#file = File.new("script/gbif_test.txt","r")

Fish.delete_all
step =0

while (line = file.gets)
  begin
    step = 1
    if !line.valid_encoding?
      step=1.1
      ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
      step=1.2
      line = ic.iconv(line)
    end
      step =1.3
    if line[-1,1] == "\n"
      step = 1.4
      fields = line.chop.split(/\t/)
    else
      step = 1.5
      fields = line.split(/\t/)
    end
    step = 2
    tax_id = fields[0].to_i
    step = 4
    sci_name = CGI::unescapeHTML fields[1]
    step = 5
    #ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
    #sci_name = ic.iconv(sci_name + ' ')[0..-2]
    #
    if fields[2].nil?
      c_name = ""
    else
      c_name = CGI::unescapeHTML fields[2]
    end
    step =6
    if Fish.where("taxonomy_id = ? AND scientific_name = ? AND name  = ? ", tax_id, sci_name, c_name).empty?   
      step = 7
      new_fish = Fish.new
      step = 8
      new_fish.scientific_name = sci_name
      step = 9
      new_fish.name = c_name
      step = 10
      new_fish.taxonomy_id = tax_id
      step = 11
      new_fish.save
      #puts "added #{sci_name} #{tax_id}  #{c_name}    (id: #{new_fish.id})"
    end
  rescue => e
    puts ">>>>>>>>>>> NEW ERROR <<<<<<<<<<<<<<"
    puts $!
    puts "Failed to add  #{sci_name} #{tax_id}  #{c_name} (id: #{new_fish.id}) on step "+step.to_s 
    puts "=============================="
    puts e.exception
    puts e.backtrace
  end
end
file.close



