
require "iconv"

class String
  def complete?
    self[0..0] != '"' or self[-1..-1] == '"'
  end
end


counter = 1

file = File.new("script/taxonomy_notes.txt", "r")
header = file.gets

TaxonomyNote.delete_all

while (line = file.gets)
begin
  print "#{counter}."

  fields = Iconv.conv("utf-8//TRANSLIT//IGNORE", "utf-16be//IGNORE", line).split(/[\t]/)

  while not fields[3].complete? do
    print "."
    line += file.gets
    fields = Iconv.conv("utf-8//TRANSLIT//IGNORE", "utf-16be//IGNORE", line).split(/[\t]/)
  end 

  #fields.each_index {|i| puts "#{i}: '#{fields[i]}'"}

  new_taxonomy = TaxonomyNote.new
  new_taxonomy.id = fields[0]
  new_taxonomy.category = fields[1]
  new_taxonomy.lang = fields[2]
  new_taxonomy.note = fields[3]
  new_taxonomy.taxonomy_id = fields[4]
  new_taxonomy.save

  counter = counter + 1
  puts

rescue
  puts ">>>>>>>>>>> ERROR <<<<<<<<<<<<<<"
  puts $!
end

end
file.close
