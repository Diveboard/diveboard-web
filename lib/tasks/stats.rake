
namespace :stats do

  desc "Importing and updating stats table"
  task :import => :environment do |t, args|
    StatHelper.load_from_access
    StatHelper.aggreg
  end

end
