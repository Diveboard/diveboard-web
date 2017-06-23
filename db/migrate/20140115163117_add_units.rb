class AddUnits < ActiveRecord::Migration
  def self.up
    add_column :dives, :maxdepth_value, :float rescue nil
    add_column :dives, :maxdepth_unit, :string rescue nil
    add_column :dives, :altitude_value, :float rescue nil
    add_column :dives, :altitude_unit, :string rescue nil
    add_column :dives, :temp_bottom_unit, :string rescue nil
    add_column :dives, :temp_bottom_value, :float rescue nil
    add_column :dives, :temp_surface_unit, :string rescue nil
    add_column :dives, :temp_surface_value, :float rescue nil
    add_column :dives, :weights_unit, :string rescue nil
    add_column :dives, :weights_value, :float rescue nil

    add_column :tanks, :p_start_unit, :string rescue nil
    add_column :tanks, :p_start_value, :float rescue nil

    add_column :tanks, :p_end_unit, :string rescue nil
    add_column :tanks, :p_end_value, :float rescue nil

    add_column :tanks, :volume_unit, :string rescue nil
    add_column :tanks, :volume_value, :float rescue nil

    puts "Columns have been created, the migration of data will take a while but you must upgrade unicorn now"
    time_start  = Time.now

    Dive.all.each{|d|
      self.update_units d
    }

    Dive.where("created_at >= ?", time_start).each{|d|
      self.update_units d
    }

    ##safetystops, weights, 
  end

  def self.update_units d
    ##use user's default units
    if begin d.user.unitSI? rescue true end
      begin
        d.maxdepth_value = d.read_attribute(:maxdepth)
        d.maxdepth_unit = "m" unless d.read_attribute(:maxdepth).nil?
      rescue
          puts "fail dive #{d.id} maxdepth #{d.read_attribute(:maxdepth)}"
      end
      begin
        d.altitude_value = d.read_attribute(:altitude)
        d.altitude_unit = "m" unless d.read_attribute(:altitude).nil?
      rescue
         puts "fail dive #{d.id} altitude #{d.read_attribute(:altitude)}"
      end
      begin
        d.temp_bottom_value = d.read_attribute(:temp_bottom)
        d.temp_bottom_unit = "C" unless d.read_attribute(:temp_bottom).nil?
      rescue
         puts "fail dive #{d.id} temp_bottom #{d.read_attribute(:temp_bottom)}"
      end
      begin
        d.temp_surface_value = d.read_attribute(:temp_surface)
        d.temp_surface_unit = "C" unless d.read_attribute(:temp_surface).nil?
      rescue
         puts "fail dive #{d.id} temp_surface #{d.read_attribute(:temp_surface)}"
      end
      begin
        d.weights_value = d.read_attribute(:weights)
        d.weights_unit = "kg" unless d.read_attribute(:weights).nil?
      rescue
         puts "fail dive #{d.id} weights #{d.read_attribute(:weights)}"
      end
      begin
        d.save
      rescue
        puts "fail save  dive #{d.id}  #{$!.message}"
        puts $!.backtrace
      end

      d.tanks.each{|t|
        begin
          t.p_start_value = d.read_attribute(:p_start)
          t.p_start_unit = "bar" unless d.read_attribute(:p_start).nil?
        rescue
          puts "fail tank #{t.id} p_start #{d.read_attribute(:p_start)}"
        end
        begin
          t.p_end_value = d.read_attribute(:p_end)
          t.p_end_unit = "bar" unless d.read_attribute(:p_end).nil?
        rescue
          puts "fail tank #{t.id} p_end #{d.read_attribute(:p_end)}"
        end
        begin
          t.volume_value = d.read_attribute(:volume)
          t.volume_unit = "L" unless d.read_attribute(:volume).nil?
        rescue
          puts "fail tank #{t.id} volume #{d.read_attribute(:volume)}"
        end
        begin
          t.save
        rescue
          puts "fail save  tank #{t.id}  #{$!.message}"
          puts $!.backtrace
        end
      }

    else
      begin
        d.maxdepth_value = Unit.new("#{d.read_attribute(:maxdepth)} m").convert_to("ft").scalar.to_f unless d.read_attribute(:maxdepth).nil?
        d.maxdepth_unit = "ft" unless d.read_attribute(:maxdepth).nil?
      rescue
          puts "fail dive #{d.id} maxdepth #{d.read_attribute(:maxdepth)}"
      end
      begin
        d.altitude_value = Unit.new("#{d.read_attribute(:altitude)} m").convert_to("ft").scalar.to_f unless d.read_attribute(:altitude).nil?
        d.altitude_unit = "ft" unless d.read_attribute(:altitude).nil?
      rescue
         puts "fail dive #{d.id} altitude #{d.read_attribute(:altitude)}"
      end
      begin
        d.temp_bottom_value = Unit.new("#{d.read_attribute(:temp_bottom)} tempC").convert_to("tempF").scalar.to_f unless d.read_attribute(:temp_bottom).nil?
        d.temp_bottom_unit = "F" unless d.read_attribute(:temp_bottom).nil?
      rescue
         puts "fail dive #{d.id} temp_bottom #{d.read_attribute(:temp_bottom)}"
      end
      begin
        d.temp_surface_value = Unit.new("#{d.read_attribute(:temp_surface)} tempC").convert_to("tempF").scalar.to_f unless d.read_attribute(:temp_surface).nil?
        d.temp_surface_unit = "F" unless d.read_attribute(:temp_surface).nil?
      rescue
         puts "fail dive #{d.id} temp_surface #{d.read_attribute(:temp_surface)}"
      end
      begin
        d.weights_value = Unit.new("#{d.read_attribute(:weights)} kg").convert_to("lbs").scalar.to_f unless d.read_attribute(:weights).nil?
        d.weights_unit = "lbs" unless d.read_attribute(:weights).nil?
      rescue
         puts "fail dive #{d.id} weights #{d.read_attribute(:weights)}"
      end
      begin
        d.save
      rescue
        puts "fail save  dive #{d.id}  #{$!.message}"
        puts $!.backtrace
      end

      d.tanks.each{|t|
        begin
          t.p_start_value = Unit.new("#{d.read_attribute(:p_start)} bar").convert_to("psi").scalar.to_f unless d.read_attribute(:p_start).nil?
          t.p_start_unit = "psi" unless d.read_attribute(:p_start).nil?
        rescue
          puts "fail tank #{t.id} p_start #{d.read_attribute(:p_start)}"
        end
        begin
          t.p_end_value = Unit.new("#{d.read_attribute(:p_end)} bar").convert_to("psi").scalar.to_f unless d.read_attribute(:p_end).nil?
          t.p_end_unit = "psi" unless d.read_attribute(:p_end).nil?
        rescue
          puts "fail tank #{t.id} p_end #{d.read_attribute(:p_end)}"
        end
        begin
          t.volume_value = Unit.new("#{d.read_attribute(:volume)} L").convert_to("cuft").scalar.to_f unless d.read_attribute(:volume).nil?
          t.volume_unit = "cuft" unless d.read_attribute(:volume).nil?
        rescue
          puts "fail tank #{t.id} volume #{d.read_attribute(:volume)}"
        end
        begin
          t.save
        rescue
          puts "fail save  tank #{t.id}  #{$!.message}"
          puts $!.backtrace
        end
      }

    end
  end

  def self.down
    remove_column :dives, :maxdepth_value
    remove_column :dives, :maxdepth_unit
    remove_column :dives, :altitude_value
    remove_column :dives, :altitude_unit
    remove_column :dives, :temp_bottom_unit
    remove_column :dives, :temp_bottom_value
    remove_column :dives, :temp_surface_unit
    remove_column :dives, :temp_surface_value
    remove_column :dives, :weights_unit
    remove_column :dives, :weights_value

    remove_column :tanks, :p_start_unit
    remove_column :tanks, :p_start_value

    remove_column :tanks, :p_end_unit
    remove_column :tanks, :p_end_value

    remove_column :tanks, :volume_unit
    remove_column :tanks, :volume_value
  end
end
