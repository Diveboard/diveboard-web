class UpdateBrInDiveNotes < ActiveRecord::Migration
  def self.up
    Dive.all.each{|d|
      if ! d.notes.nil? then d.notes = d.notes.gsub(/<br\/>/i, "\n") end
      d.save
    }
  end

  def self.down
    Dive.all.each{|d|
      if ! d.notes.nil? then d.notes = d.notes.gsub(/[\n\r]/, "<br/>") end
      d.save
    }
  end
end
