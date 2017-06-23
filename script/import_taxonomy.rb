

require "iconv"

class String
  def complete?
    self[0..0] != '"' or self[-1..-1] == '"'
  end
end

counter = 1

file = File.new("script/taxonomy.txt", "r")
header = file.gets

Taxonomy.delete_all

while (line = file.gets)
begin
  print "#{counter}."

  fields = Iconv.conv("utf-8//TRANSLIT//IGNORE", "utf-16be", line).split(/[\t]/)

  while not (fields[1].complete? and fields[2].complete? and fields[3].complete? and fields[15].complete?) do 
    print "."
    line += file.gets
    fields = Iconv.conv("utf-8//TRANSLIT//IGNORE", "utf-16be", line).split(/[\t]/)
  end 

  #fields.each_index {|i| puts "#{i}: '#{fields[i]}'"}

  new_taxonomy = Taxonomy.new

  new_taxonomy.id = fields[0]
  new_taxonomy.name = fields[1]
  new_taxonomy.displayname = fields[2]
  new_taxonomy.authority = fields[3]
  new_taxonomy.taxonomy_parent = fields[4]
  new_taxonomy.rank = fields[5]
  new_taxonomy.acctaxon = fields[6]
  new_taxonomy.status = fields[7]
  new_taxonomy.unacceptreason = fields[8]
  new_taxonomy.marine = fields[9]
  new_taxonomy.brackish = fields[10]
  new_taxonomy.fresh = fields[11]
  new_taxonomy.terrestrial = fields[12]
  new_taxonomy.fossil = fields[13]
  new_taxonomy.hidden = fields[14]
  new_taxonomy.hierarchy = fields[15]

  new_taxonomy.save

  counter = counter + 1

  puts "      (id: #{new_taxonomy.id})"
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


