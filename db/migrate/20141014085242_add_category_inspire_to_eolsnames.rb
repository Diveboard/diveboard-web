class AddCategoryInspireToEolsnames < ActiveRecord::Migration
  def up
    add_column :eolsnames, :category_inspire, :string
    Eolsname.reset_column_information
    id_to_category = Hash[ [ [8882, "manta"], [8898, "ray"], [1858, "ray"], [2775391, "ray"], [1857, "shark"], [8898, nil], [1858, nil], [2775391, nil], [7659, "dolphin"], [7649, "whales"], [7659, nil], [6893, "schools"], [5310, "sailfish"], [8120, "turtle"], [8280, "eels"], [5064, "seahorse"], [24566, "clownfish"], [8708, "dugong"], [24659, "lionfish"], [5202, "barracuda"], [24039, "grouper"], [24689, "grouper"], [27865, "grouper"], [25416, "grouper"], [24424, "grouper"], [99524, "grouper"], [26620, "grouper"], [24209, "grouper"], [23843, "grouper"], [27113, "grouper"], [26375, "grouper"], [24679, "grouper"], [24210, "grouper"], [28230, "grouper"], [24787, "grouper"], [26822, "grouper"], [26823, "grouper"], [101681, "grouper"], [23960, "grouper"], [5061, "triggerfish"], [5056, "pufferfish"], [7174, "lobster"], [7383, "mantis_shrimp"], [2538, "nudibranch"], [1927, "starfish"], [1802, "jellyfish"], [7666, "seal"], [2312, "octopus"], [2560232, "tubeworm"], [5319, "gobie"] ] ]
    id_to_category.each do |key, value|
      puts "Work on  id " + key.to_s
      e = Eolsname.find_by_id(key)
      if e.nil? then
        puts "ID #{key} DOES NOT EXIST !!!!!"
        next
      end
      e.category_inspire = value
      e.save
      e.get_all_children.each do |c|
        c.category_inspire = value
        c.save
      end
    end
  end
  def down
    remove_column :eolsnames, :category_inspire
  end
end
