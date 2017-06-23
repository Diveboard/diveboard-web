#!/usr/bin/ruby
##this script is used by TeamCity to run the unit tests on staging ... as if it was locally
puts "running rake dbtest:units on stage env"
output = `ssh diveboard@stage.diveboard.com 'cd /home/diveboard/diveboard-web/current && /usr/local/bin/bundle exec rake dbtest:units RAILS_ENV=staging'`
puts output
result=$?.success?
if result == true
  exit(0)
else
  exit(-1)
end