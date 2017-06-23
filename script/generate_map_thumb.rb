Spot.all.each do |spot|
  sleep = 2
  if %x{shasum "public/map_images/map_#{spot.id}.jpg"}.match(/[a-z0-9]*/).to_s == %x{shasum "public/map_images/map_error.jpg"}.match(/[a-z0-9]*/).to_s
    File.delete("public/map_images/map_#{spot.id}.jpg")
  end
  if !File.exists?("public/map_images/map_#{spot.id}.jpg")
    spot.cache_static_map
    sleep(sleep)
  end
  if %x{shasum "public/map_images/map_#{spot.id}.jpg"}.match(/[a-z0-9]*/).to_s == %x{shasum "public/map_images/map_error.jpg"}.match(/[a-z0-9]*/).to_s
     File.delete("public/map_images/map_#{spot.id}.jpg")
     puts ">>>>>>>>>>> ERROR <<<<<<<<<<<<<<"
     puts "We probably maxed out the Google api, they send us a wrong image for file map_#{spot.id}.jpg, increasing sleep"
     sleep = 5
   end
end