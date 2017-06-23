rails_env= `echo $RAILS_ENV`.chop
puts "This will mirror everything from prod to your local environment, #{rails_env}"
puts "   'rails runner script/update_local_env.rb dblight username' to NOT include the fish db in the mirror NOR the files"
puts "   'rails runner script/update_local_env.rb dbfull username' to include the fish db in the mirror ANDNOT the files"
puts "   'rails runner script/update_local_env.rb full username' to include the fish db in the mirror AND the files"
puts "   'rails runner script/update_local_env.rb files username' to include ONLY the files"
puts "   'rails runner script/update_local_env.rb backup username ' will archive local files +db in /tmp/diveboard.tar.gz"
puts "   'rails runner script/update_local_env.rb restore username' will restore local files + db from /tmp/diveboard.tar.gz"



if ARGV[0] == "dblight"
  puts "Import will be light"
elsif ARGV[0] == "full"
  puts "Import will be full DB+FILES"
elsif ARGV[0] == "dbfull"
  puts "Import will be full DB+FILES"
elsif ARGV[0] == "files"
  puts "Import will be full FILES"
else
  puts "RTFM !"
  exit
end

if ARGV[1].nil?
  ssh_user = "diveboard"
else
  ssh_user = ARGV[1]
end
puts "\n\nWARNING : you must be able to ssh #{ssh_user}@diveboard.com  u can override username diveboard by the one you want\n\n"



domain = "diveboard.com"

time = Time.now.strftime("%Y%h%m%s%u")

#####
#####LOCAL ENV
config = Rails.application.config
database = config.database_configuration[rails_env]["database"]
username = config.database_configuration[rails_env]["username"]
password = config.database_configuration[rails_env]["password"]
socket = config.database_configuration[rails_env]["socket"]
client = Mysql2::Client.new(:database => database, :username => username, :password => password, :socket => socket)

######
######REMOTE ENV
prod_db = config.database_configuration["production"]["database"]
prod_user = config.database_configuration["production"]["username"]
prod_pass = "VZfs591bnw32d" #config.database_configuration["production"]["password"]


system `mkdir -p uploads public/tmp_upload public/user_images public/map_images public/assets pages db/sphinx tmp`


### make a new db_dump
if ARGV[0] == "dblight" || ARGV[0] == "dbfull" || ARGV[0] == "full"
  mysqldump = "ionice -c 3 nice -n 10 mysqldump --lock-tables=false  --user=#{prod_user} --password='#{prod_pass}' "
  mysqldump += " --tab=/tmp/#{time}-diveboard.exp "
  if ARGV[0] == "dblight"
    mysqldump += "--ignore-table=diveboard.fishes  --ignore-table=diveboard.eolcnames  --ignore-table=diveboard.eolsnames --ignore-table=diveboard.geonames_alternate_names --ignore-table=diveboard.geonames_cores --ignore-table=diveboard.fish_frequencies  --ignore-table=diveboard.sessions --ignore-table=diveboard.stats_logs --ignore-table=diveboard.stats_sums "
  else
    mysqldump += "--ignore-table=diveboard.sessions --ignore-table=diveboard.stats_logs "
  end
  mysqldump += "#{prod_db}"
  ssh_sql = "ssh #{ssh_user}@#{domain} '#{mysqldump}'"
  puts "Dumping prod DB with command : #{ssh_sql}"
  system "ssh #{ssh_user}@#{domain} 'mkdir /tmp/#{time}-diveboard.exp'"
  system "ssh #{ssh_user}@#{domain} 'chmod 777 /tmp/#{time}-diveboard.exp'"
  system ssh_sql

  gzip ="ssh #{ssh_user}@#{domain} 'ionice -c 3 nice -n 10 tar zcf /tmp/#{time}-diveboard.tgz -C /tmp/ #{time}-diveboard.exp'"
  puts "zipping"
  system gzip 

  scp = "scp #{ssh_user}@#{domain}:/tmp/#{time}-diveboard.tgz #{Rails.root}/tmp/#{time}-diveboard.tgz"
  puts "Copying prod db"
  system scp

  gunzip = "tar zxf #{Rails.root}/tmp/#{time}-diveboard.tgz -C #{Rails.root}/tmp/"
  puts "unzipping"
  system gunzip

  del_dump = "ssh #{ssh_user}@#{domain} 'rm -rf /tmp/#{time}-diveboard.tgz /tmp/#{time}-diveboard.exp'"
  puts "Cleaning up remote dump"
  system del_dump

  if ARGV[0] == "dblight"
    empty_local = "echo 'show full tables' | mysql -s --user=#{username} --password='#{password}'  #{database} |  grep -Ev '^(fishes|eolcnames|eolsnames|geonames_alternate_names|geonames_cores|fish_frequencies|sessions|stats_logs|stats_sums)[[:blank:]]' | sed -E 's/([^[:blank:]]*).*(TABLE|VIEW)/DROP \\2 \\1;/' | mysql -u#{username} -p'#{password}' #{database}"
  else
    empty_local =  "mysqldump -u#{username} -p'#{password}' --add-drop-table --no-data #{database} | grep ^DROP | mysql -u#{username} -p'#{password}' #{database}"
  end
  puts "purging local db"
  system empty_local
  
  #users table is used within views, so it must be the first restored
  import_sql = "cat #{Rails.root}/tmp/#{time}-diveboard.exp/users.sql #{Rails.root}/tmp/#{time}-diveboard.exp/shops.sql #{Rails.root}/tmp/#{time}-diveboard.exp/*.sql | grep -v '^/.!50013 DEFINER=' | mysql --user=#{username} --password='#{password}'  #{database}"
  puts "creating schema"
  system import_sql

  import_sql = "mysqlimport --local --user=#{username} --password='#{password}'  #{database} #{Rails.root}/tmp/#{time}-diveboard.exp/*.txt"
  puts "importing db"
  system import_sql

  puts "deletin db file"
  system "rm -rf #{Rails.root}/tmp/#{time}-diveboard.tgz /tmp/#{time}-diveboard.exp"
end

if ARGV[0] == "dblight" || ARGV[0] == "dbfull"
  puts "Skipping file import"
else
  #['public/map_images', 'public/assets'].each do |path|
  ['public/assets'].each do |path|
    puts "Synchronizing the share folder : #{path}"
    system "rsync -rltpz --delete #{ssh_user}@#{domain}:/home/diveboard/diveboard-web/shared/#{path}/ #{path}/"
  end

  #puts "Synchronizing the share folder : public/user_images"
  #system "rsync -rltpz --delete --exclude='*original*' --exclude='*image*' --exclude='*video*' #{ssh_user}@#{domain}:/home/diveboard/diveboard-web/shared/public/user_images/ public/user_images/"

  puts "cleaning up"
  system "rm -rf #{Rails.root}/tmp/#{time}"
end
puts "DONE!!!!!"


