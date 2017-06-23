namespace :area do

  adding_size = 2.0
  offset = 0

  task :category => :environment do
    AreaCategory.delete_all
    ActiveRecord::Base.connection.execute('ALTER TABLE area_categories AUTO_INCREMENT = 1')
    puts "Start calculing the category for all areas"
    i = 0
    total = Area.offset(offset).all.size
    Area.offset(offset).map(&:id).each do |area_id| 
      a = Area.find(area_id)
      i += 1
      print "\rArea " + i.to_s + "/" + total.to_s + " traited"

      a.minLat -= adding_size
      a.minLng -= adding_size
      a.maxLat += adding_size
      a.maxLng += adding_size

      category_hash = Hash.new
      a.dives.each do |d|
        d.species.each do |s|
          category = s[:category_inspire]
          if !category.nil?
            if !category_hash.has_key?(category)
              category_hash[category] = 0
            end
            category_hash[category] += 1
          end
        end
      end

      category_hash.each do |key, value|
        if key != "other" && key != "unclassified"
          area_category = AreaCategory.where("area_id = ? AND category = ?", a.id, key).first
          if (area_category.nil?)
            area_category = AreaCategory.new
            area_category.category = key
            area_category.area = a
          end
          area_category.count = value
          area_category.save
        end
      end
    end
    puts "\nFinish calculing"
  end

  task :attendance => :environment do
    puts "Start calculing the attendance for all areas"
    i = 0
    total = Area.all.size
    Area.all.each do |a|
      i += 1
      print "\rArea " + i.to_s + "/" + total.to_s + " traited"
      a.january = 0
      a.february = 0
      a.march = 0
      a.april = 0
      a.may = 0
      a.june = 0
      a.july = 0
      a.august = 0
      a.september = 0
      a.october = 0
      a.november = 0
      a.december = 0

      minLat = a.minLat
      minLng = a.minLng
      maxLat = a.maxLat
      maxLng = a.maxLng


      a.minLat -= adding_size
      a.minLng -= adding_size
      a.maxLat += adding_size
      a.maxLng += adding_size
      a.dives.each do |d|
        case d.time_in.month
        when 1
          a.january += 1
        when 2
          a.february += 1
        when 3
          a.march += 1
        when 4
          a.april += 1
        when 5
          a.may += 1
        when 6
          a.june += 1
        when 7
          a.july += 1
        when 8
          a.august += 1
        when 9
          a.september += 1
        when 10
          a.october += 1
        when 11
          a.november += 1
        when 12
          a.december += 1
        end
      end
      a.minLat = minLat
      a.minLng = minLng
      a.maxLat = maxLat
      a.maxLng = maxLng
      a.save
    end
    puts "\nFinish calculing"
  end

  task :active => :environment do
    puts "Activate Area"
    i = 0
    total = Area.all.size
    Area.all.each do |a|
      i += 1
      print "\rArea " + i.to_s + "/" + total.to_s + " traited"
      reviews = a.dives_order_by_overall_and_notes 5
      if a.best_pictures.count != 0 && reviews.count != 0
        a.active = true
      else
        a.active = false
      end
      a.save
    end
    puts "\nFinish calculing"
  end
end