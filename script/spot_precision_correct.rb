## Corrects the procision of the spot location in DB ... koz I messed it up (@alex)
## currently this does not work
file = File.new("script/20110428_2.sql", "r")
spotupdated = 0
while (line = file.gets)
    fields = line.split(/,/)
    lat = ((fields[2].gsub(/\'/,"").to_f*1000).round).to_f/1000
    long = ((fields[3].gsub(/\'/,"").to_f*1000).round).to_f/1000
    puts "search spot at #{lat}:#{long}"
    spots = Spot.where("name LIKE ? and location LIKE ?", "#{fields[1]}","#{fields[4]}")
    spots.each do |sspot|
      sspot.lat = fields[2].gsub(/\'/,"").to_f
      sspot.long = fields[3].gsub(/\'/,"").to_f
      sspot.save
      puts "updated spot #{sspot.id}"
      spotupdated = spotupdated+1
    end
end
puts "migration complete : #{spotupdated} spots updated "