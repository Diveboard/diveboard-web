

require "iconv"

class String
  def complete?
    self[0..0] != '"' or self[-1..-1] == '"'
  end
end

class NilClass
  def complete?
    true
  end
end

counter = 1

file = File.new("script/vernacular_en.txt", "r")
header = file.gets

Fish.delete_all


while (line = file.gets)
begin
  print "#{counter}."

  fields = Iconv.conv("utf-8", "utf-16be", line).chomp.split(/[\t]/)

  while not (fields[2].complete? and fields[5].complete? ) do 
    print "."
    print ">>>"+fields[2]+"<<<\n"
    line += file.gets
    fields = Iconv.conv("utf-8", "utf-16be", line).chomp.split(/[\t]/)
  end 

  next unless fields[3] = "en"

  #fields.each_index {|i| puts "#{i}: '#{fields[i]}'"}

  new_fish = Fish.new

  new_fish.id = fields[0]
  new_fish.name = fields[2]
  new_fish.taxonomy_id = fields[1]
  new_fish.preferred = fields[4]

  new_fish.save

  counter = counter + 1

  puts "      (id: #{new_fish.id})"
rescue
  puts ">>>>>>>>>>> ERROR <<<<<<<<<<<<<<"
  puts $!

end
end
file.close







#id: integer
#name: string
#displayname: string
#authority: string
#taxonomy_parent: integer
#rank: integer
#acctaxon: integer
#status: integer
#unacceptreason: string
#marine: integer
#brackish: integer
#fresh: integer
#terrestrial: integer
#fossil: integer
#hidden: integer
#hierarchy: string
#created_at: datetime
#updated_at: datetime)
#
#
#
#int id
#tu_name
#tu_displayname
#tu_authority
#int tu_parent
#int tu_rank
#int tu_acctaxon
#int tu_status
#int tu_unacceptreason
#int tu_marine
#int tu_brackish
#int tu_fresh
#int tu_terrestrial
#int tu_fossil
#int tu_hidden
#tu_sp
#362641 hureaui Copidognathus hureaui Newell, 1984 114765 220 362641 1  1 0 0 0  0       #2#1065#1274#1300#1349#1414#292685#1484#114765#
#
#
#
#
#


