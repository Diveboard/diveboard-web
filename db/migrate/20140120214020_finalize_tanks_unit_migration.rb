class FinalizeTanksUnitMigration < ActiveRecord::Migration
  def self.up

    Tank.all.each {|t|
      if (begin t.dive.user.unitSI? rescue true end)
        begin
          t.p_start_value = t.read_attribute(:p_start)
          t.p_start_unit = "bar" unless t.read_attribute(:p_start).nil?
        rescue
          puts "fail tank #{t.id} p_start #{t.read_attribute(:p_start)}"
        end
        begin
          t.p_end_value = t.read_attribute(:p_end)
          t.p_end_unit = "bar" unless t.read_attribute(:p_end).nil?
        rescue
          puts "fail tank #{t.id} p_end #{t.read_attribute(:p_end)}"
        end
        begin
          t.volume_value = t.read_attribute(:volume)
          t.volume_unit = "L" unless t.read_attribute(:volume).nil?
        rescue
          puts "fail tank #{t.id} volume #{t.read_attribute(:volume)}"
        end
        begin
          t.save
        rescue
          puts "fail save  tank #{t.id}  #{$!.message}"
          puts $!.backtrace
        end
      else
        begin
          t.p_start_value = Unit.new("#{t.read_attribute(:p_start)} bar").convert_to("psi").scalar.to_f unless t.read_attribute(:p_start).nil?
          t.p_start_unit = "psi" unless t.read_attribute(:p_start).nil?
        rescue
          puts "fail tank #{t.id} p_start #{t.read_attribute(:p_start)}"
        end
        begin
          t.p_end_value = Unit.new("#{t.read_attribute(:p_end)} bar").convert_to("psi").scalar.to_f unless t.read_attribute(:p_end).nil?
          t.p_end_unit = "psi" unless t.read_attribute(:p_end).nil?
        rescue
          puts "fail tank #{t.id} p_end #{t.read_attribute(:p_end)}"
        end
        begin
          t.volume_value = Unit.new("#{t.read_attribute(:volume)} L").convert_to("cuft").scalar.to_f unless t.read_attribute(:volume).nil?
          t.volume_unit = "cuft" unless t.read_attribute(:volume).nil?
        rescue
          puts "fail tank #{t.id} volume #{t.read_attribute(:volume)}"
        end
        begin
          t.save
        rescue
          puts "fail save  tank #{t.id}  #{$!.message}"
          puts $!.backtrace
        end
      end
    }



  end

  def self.down
  end
end

