
namespace :sanity do

  desc "Running all sanity checks"
  task :all => :environment do |t,args|
    ["sanity:picture_upload"].each do |t|
      Rake::Task[t].execute
    end
  end

  desc "Trying to make sure all pictures are correctly uploaded on google storage"
  task :picture_upload => :environment do |t, args|
    (Picture.where 'thumb_id is null or small_id is null or medium_id is null or large_id is null or original_image_id is null').map &:upload_thumbs_without_delay
  end

end
