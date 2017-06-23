
namespace :facebook do

  desc "Post the latest great picture to Diveboard page"
  task :post_great_pic  => :environment do |t, args|
    Picture.where(great_pic: true, fb_graph_id: nil).where('width >= 1200 and width > 1.3 * height and width < 2.3 * height').order('ADDDATE(pictures.created_at, interval pictures.id%7 day) DESC').limit(100).each do |pic|
      next if pic.dive.nil?
      next if pic.dive.privacy == 1
      Rails.logger.info "Publishing to facebook picture #{pic.id} : #{pic.fullpermalink}"
      pic.publish_to_fb_as_link
      break
    end
  end

end
