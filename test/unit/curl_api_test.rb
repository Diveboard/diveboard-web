require 'test_helper'

class CurlApiTest < ActiveSupport::TestCase
  setup :start
  teardown :shutdown

  def start
    FileUtils.touch Rails.configuration.root.join("tmp", "restart.txt")
    @root_url = ROOT_URL.gsub /\/$/, ''
    @api_key = generate_new_apikey
    @fb_user = create_fb_user_test
  end

  def shutdown
    drop_test_fb_user @fb_user
  end


  #Helpers

  def rand_email
    alphanumerics = ('a'..'z').to_a
    alphanumerics = alphanumerics.concat(('0'..'9').to_a)
    email_head=''
    12.times{ email_head <<  alphanumerics[rand(alphanumerics.size - 1)]}
    return email_head+"@diveboard.com"
  end

  def rand_name
    alphanumerics = ('a'..'z').to_a
    alphanumerics = alphanumerics.concat(('0'..'9').to_a)
    alphanumerics.push ' '
    name=''
    12.times{ name <<  alphanumerics[rand(alphanumerics.size - 1)]}
    return name
  end

  def generate_new_apikey
    api_key = self.rand_name
    ApiKey.create :key => @api_key, :user_id => User.first.id, :comment => "Unit test key"
    return api_key
  end

  def make_system_call call_string
    real_call_string = call_string.split("\n").map(&:strip).join(' ')
    puts "\n<<<<<  REQUEST  >>>>>"
    puts call_string.split("\n").map(&:strip).join("\n")
    out = IO.popen(real_call_string)
    ans = out.readlines.join("\n")
    puts "\n<<<<<  RESPONSE  >>>>>"
    puts ans
    puts ""
    return JSON.parse(ans)
  end

  def create_fb_user_test
    puts "Creating test user on Facebook"
    test_users = Koala::Facebook::TestUsers.new(:app_id => FB_APP_ID, :secret => FB_APP_SECRET)
    return test_users.create(true, "publish_stream,email,publish_checkins,user_photos,user_videos")
  end

  def drop_test_fb_user fb_user
    puts "Deleting test user on Facebook"
    test_users = Koala::Facebook::TestUsers.new(:app_id => FB_APP_ID, :secret => FB_APP_SECRET)
    test_users.delete(fb_user['id'])
  end




  test "curl_doc" do

    puts "=================================================\n"
    puts "Example to log in a user with his facebook ID and facebook token"

    ret = make_system_call <<CURL
      curl -s "#{@root_url}/api/login_fb"
      -F "fbid=#{@fb_user["id"]}"
      -F "fbtoken=#{@fb_user["access_token"]}"
      -F "apikey=#{@api_key}"
CURL

    assert_equal ret['success'], true
    assert !ret['token'].blank?
    @auth_token = ret['token']
    @user_shaken_id = ret['id']


    puts "=================================================\n"
    puts "Example to register a vanity url"

    ret = make_system_call <<CURL
      curl -s "#{@root_url}/api/register_vanity_url"
      -F 'token=#{@auth_token}'
      -F 'vanity_url=user_curl_#{@user_shaken_id}'
      -F "apikey=#{@api_key}"
CURL

    assert_equal ret['success'], true



    puts "=================================================\n"
    puts "Example to get the basic details for a user"
    ret = make_system_call <<CURL
      curl -s "#{@root_url}/api/V2/user/#{@user_shaken_id}"
      -F "apikey=#{@api_key}"
CURL

    assert_equal ret['success'], true
    assert_equal ret['error'], []
    assert_equal ret['result']['shaken_id'], @user_shaken_id
    assert_equal ret['result']['vanity_url'], "user_curl_#{@user_shaken_id}".downcase
    @user_vanity = ret['result']['vanity_url']
    @user_id = ret['result']['id']

    puts "=================================================\n"
    puts "Example to get the more details for a user"
    ret = make_system_call <<CURL
      curl -s "#{@root_url}/api/V2/user"
      -F 'arg={"id":"#{@user_id}"}'
      -F 'flavour=private'
      -F 'auth_token=#{@auth_token}'
      -F "apikey=#{@api_key}"
CURL

    assert_equal ret['success'], true
    assert_equal ret['error'], []
    assert_equal ret['result']['id'], @user_id
    assert_equal ret['result']['shaken_id'], @user_shaken_id


    puts "=================================================\n"
    puts "Example to update the nickname of a user"
    ret = make_system_call <<CURL
      curl -s "#{@root_url}/api/V2/user"
      -F 'arg={"id":"#{@user_id}", "nickname":"New Nick"}'
      -F 'auth_token=#{@auth_token}'
      -F "apikey=#{@api_key}"
CURL

    assert_equal ret['success'], true
    assert_equal ret['error'], []
    assert_equal ret['result']['id'], @user_id
    assert_equal ret['result']['nickname'], "New Nick"


    puts "=================================================\n"
    puts "Example to create a dive"
    ret = make_system_call <<CURL
      curl -s "#{@root_url}/api/V2/dive"
      -F 'auth_token=#{@auth_token}'
      -F "apikey=#{@api_key}"
      -F 'arg={"user_id": "#{@user_shaken_id}", "duration": 90, "maxdepth":40, "time_in": "2011-10-16T09:40:00Z", "spot":{"id":1843}}'
CURL

    assert_equal ret['success'], true
    assert_equal ret['error'], []
    assert_equal ret['result']['user_id'], @user_id
    assert_equal ret['result']['duration'], 90
    assert_equal ret['result']['maxdepth'], 40.0
    assert_equal ret['result']['spot_id'], 1843
    dive_id = ret['result']['id']


    puts "=================================================\n"
    puts "Example to update both the duration and the depth on a dive"
    ret = make_system_call <<CURL
      curl -s "#{@root_url}/api/V2/dive"
      -F 'auth_token=#{@auth_token}'
      -F "apikey=#{@api_key}"
      -F 'arg={"id": "#{dive_id}", "duration": 50, "maxdepth":50}'
CURL

    assert_equal ret['success'], true
    assert_equal ret['error'], []
    assert_equal ret['result']['user_id'], @user_id
    assert_equal ret['result']['duration'], 50
    assert_equal ret['result']['maxdepth'], 50.0
    assert_equal ret['result']['spot_id'], 1843


    puts "=================================================\n"
    puts "Example to add a dive profile to a dive"
    ret = make_system_call <<CURL
      curl -s "#{@root_url}/api/V2/dive"
      -F 'auth_token=#{@auth_token}'
      -F "apikey=#{@api_key}"
      -F 'flavour=public,dive_profile'
      -F 'arg={"id": "#{dive_id}", "raw_profile":[{"seconds":0, "depth":0}, {"seconds":30, "depth":3}, {"seconds":60, "depth":5}, {"seconds":90, "depth":10}, {"seconds":2900, "depth":10}, {"seconds":3000, "depth":0} ]}'
CURL

    assert_equal ret['success'], true
    assert_equal ret['error'], []
    assert_equal ret['result']['id'], dive_id
    assert_equal ret['result']['user_id'], @user_id
    assert_equal ret['result']['raw_profile'].count, 6
    assert_equal ret['result']['raw_profile'][0]['depth'], 0
    assert_equal ret['result']['raw_profile'][1]['depth'], 3
    assert_equal ret['result']['raw_profile'][2]['depth'], 5
    assert_equal ret['result']['raw_profile'][3]['depth'], 10
    assert_equal ret['result']['raw_profile'][4]['depth'], 10
    assert_equal ret['result']['raw_profile'][5]['depth'], 0


    puts "=================================================\n"
    puts "Example to create a gear element for a user"
    ret = make_system_call <<CURL
      curl -s "#{@root_url}/api/V2/user"
      -F 'auth_token=#{@auth_token}'
      -F 'flavour=private'
      -F "apikey=#{@api_key}"
      -F 'arg={"id":"#{@user_id}", "user_gears": [{"category":"Computer", "model":"Vyper", "manufacturer":"Suunto"}]}'
CURL

    assert_equal ret['success'], true
    assert_equal ret['error'], []
    assert_equal ret['result']['id'], @user_id
    assert_equal ret['result']['user_gears'].count, 1
    assert_equal ret['result']['user_gears'].first['manufacturer'], "Suunto"
    assert_equal ret['result']['user_gears'].first['model'], "Vyper"
    user_gear_id = ret['result']['user_gears'].first['id']


    puts "=================================================\n"
    puts "Example to add the gear 1 to a dive"
    ret = make_system_call <<CURL
      curl -s "#{@root_url}/api/V2/dive"
      -F 'auth_token=#{@auth_token}'
      -F "apikey=#{@api_key}"
      -F 'arg={"id":#{dive_id}, "user_gears":[{"id":#{user_gear_id}}]}'
CURL

    assert_equal ret['success'], true
    assert_equal ret['error'], []
    assert_equal ret['result']['user_id'], @user_id
    assert_equal ret['result']['duration'], 50
    assert_equal ret['result']['maxdepth'], 50.0
    assert_equal ret['result']['spot_id'], 1843
    assert_equal ret['result']['user_gears'].count, 1
    assert_equal ret['result']['user_gears'].first['manufacturer'], "Suunto"
    assert_equal ret['result']['user_gears'].first['model'], "Vyper"
    assert_equal ret['result']['user_gears'].first['id'], user_gear_id


    puts "=================================================\n"
    puts "Example to remove all user_gears from a dive"
    ret = make_system_call <<CURL
      curl -s "#{@root_url}/api/V2/dive"
      -F 'auth_token=#{@auth_token}'
      -F "apikey=#{@api_key}"
      -F 'arg={"id":#{dive_id}, "user_gears":[]}'
CURL

    assert_equal ret['success'], true
    assert_equal ret['error'], []
    assert_equal ret['result']['user_id'], @user_id
    assert_equal ret['result']['user_gears'], []


    puts "=================================================\n"
    puts "Example to delete a dive"
    ret = make_system_call <<CURL
      curl -X DELETE -s "#{@root_url}/api/V2/dive/#{dive_id}"
      -F 'auth_token=#{@auth_token}'
      -F "apikey=#{@api_key}"
CURL

    assert_equal ret['success'], true
    assert_equal ret['error'], []
    assert_equal ret['result'], nil

    puts "=================================================\n"
    puts "Example of error while fetching unknown dive"
    ret = make_system_call <<CURL
      curl -s "#{@root_url}/api/V2/dive/#{dive_id}"
      -F 'auth_token=#{@auth_token}'
      -F "apikey=#{@api_key}"
CURL

    assert_equal ret['success'], true
    assert_equal ret['error'].count, 1
    assert ret['error'].first.match /Object does not exist/
    assert_equal ret['result'], nil


    puts "=================================================\n"
    puts "Example of creating several dives in a single call"
    ret = make_system_call <<CURL
      curl -s "#{@root_url}/api/V2/dive"
      -F 'auth_token=#{@auth_token}'
      -F "apikey=#{@api_key}"
      -F 'arg=[{"user_id": "#{@user_shaken_id}", "duration": 90, "maxdepth":40, "time_in": "2011-10-16T09:40:00Z", "spot":{"id":1843}},{"user_id": "#{@user_shaken_id}", "duration": 50, "maxdepth":50, "time_in": "2011-10-17T09:40:00Z", "spot":{"id":1843}}]'
CURL

    assert_equal ret['success'], true
    assert_equal ret['error'], []
    assert_equal ret['result'].count, 2
    assert_equal ret['result'][0]['duration'], 90
    assert_equal ret['result'][0]['maxdepth'], 40
    assert_equal ret['result'][1]['duration'], 50
    assert_equal ret['result'][1]['maxdepth'], 50
    dive0_id = ret['result'][0]['id']
    dive1_id = ret['result'][1]['id']

    puts "=================================================\n"
    puts "Example of updating several dives in a single call"
    ret = make_system_call <<CURL
      curl -s "#{@root_url}/api/V2/dive"
      -F 'auth_token=#{@auth_token}'
      -F "apikey=#{@api_key}"
      -F 'arg=[{"id":#{dive0_id},"duration": 91},{"id":#{dive1_id},"maxdepth":51}]'
CURL

    assert_equal ret['success'], true
    assert_equal ret['error'], []
    assert_equal ret['result'].count, 2
    assert_equal ret['result'][0]['id'], dive0_id
    assert_equal ret['result'][1]['id'], dive1_id
    assert_equal ret['result'][0]['duration'], 91
    assert_equal ret['result'][0]['maxdepth'], 40
    assert_equal ret['result'][1]['duration'], 50
    assert_equal ret['result'][1]['maxdepth'], 51


    puts "=================================================\n"
    puts "Example to create a new user_gear and assigning an existing user_gear to a dive"
    ret = make_system_call <<CURL
      curl -s "#{@root_url}/api/V2/dive"
      -F 'auth_token=#{@auth_token}'
      -F "apikey=#{@api_key}"
      -F 'flavour=private'
      -F 'arg={"id":#{dive0_id}, "user_gears":[{"id":#{user_gear_id}}, {"user_id":#{@user_id},"category":"Computer","manufacturer":"Mares","model":"Icon HD"}]}'
CURL

    assert_equal ret['success'], true
    assert_equal ret['error'], []
    assert_equal ret['result']['id'], dive0_id
    assert_equal ret['result']['user_gears'].count, 2
    assert_equal ret['result']['user_gears'][0]['id'], user_gear_id
    assert_equal ret['result']['user_gears'][0]['model'], "Vyper"
    assert_equal ret['result']['user_gears'][1]['model'], "Icon HD"
    user_gear0_id = ret['result']['user_gears'][0]['id']
    user_gear1_id = ret['result']['user_gears'][1]['id']


    puts "=================================================\n"
    puts "Example to update recursively a dive and a user_gear in the same call"
    ret = make_system_call <<CURL
      curl -s "#{@root_url}/api/V2/dive"
      -F 'auth_token=#{@auth_token}'
      -F "apikey=#{@api_key}"
      -F 'flavour=private'
      -F 'arg={"id":#{dive0_id}, "duration":55, "user_gears":[{"id":#{user_gear_id}, "model":"Vyper Air"}]}'
CURL

    assert_equal ret['success'], true
    assert_equal ret['error'], []
    assert_equal ret['result']['id'], dive0_id
    assert_equal ret['result']['duration'], 55
    assert_equal ret['result']['user_gears'].count, 1
    assert_equal ret['result']['user_gears'][0]['id'], user_gear_id
    assert_equal ret['result']['user_gears'][0]['model'], "Vyper Air"
    assert_equal ret['result']['user_gears'][0]['manufacturer'], "Suunto"



    puts "=================================================\n"
    puts "Example to create a dive with spot"
    ret = make_system_call <<CURL
      curl -s "#{@root_url}/api/V2/dive"
      -F 'auth_token=#{@auth_token}'
      -F "apikey=#{@api_key}"
      -F 'flavour=private'
      -F 'arg={"user_id": "#{@user_shaken_id}", "duration": 90, "maxdepth":40, "time_in": "2011-10-16T09:40:00Z", "spot": {"name":"Blue hole", "country_code":"MT","location":{"name":"Gozo"}, "region":{"name":"Mediterranean Sea"}}}'
CURL

    assert_equal ret['success'], true
    assert_equal ret['error'], []
    assert_equal ret['result']['user_id'], @user_id
    assert_equal ret['result']['duration'], 90
    assert_equal ret['result']['maxdepth'], 40.0
    dive_url = ret['result']['fullpermalink']
    spot_id = ret['result']['spot_id']

    puts "=================================================\n"
    puts "Example to get the details of a spot"
    ret = make_system_call <<CURL
      curl -s "#{@root_url}/api/V2/spot/#{spot_id}"
      -F 'auth_token=#{@auth_token}'
      -F "apikey=#{@api_key}"
CURL

    assert_equal ret['success'], true
    assert_equal ret['error'], []
    assert_equal ret['result']['id'], spot_id
    assert_equal ret['result']['country_name'], "Malta"
    assert_equal ret['result']['location_name'], "Gozo"
    assert_equal ret['result']['region_name'], "Mediterranean Sea"


    # Checking the web page for the dive
    page = Net::HTTP.get_response(URI.parse(dive_url))
    assert_equal page.code, "200"
    assert page.body.match(/2011-10-16 - 09:40/)



    puts "=================================================\n"
    puts "Example to create a dive with some unknown named spot"
    ret = make_system_call <<CURL
      curl -s "#{@root_url}/api/V2/dive"
      -F 'auth_token=#{@auth_token}'
      -F "apikey=#{@api_key}"
      -F 'flavour=private'
      -F 'arg={"user_id": "#{@user_shaken_id}", "duration": 90, "maxdepth":40, "time_in": "2011-10-16T09:40:00Z", "spot": {"name":"Blue hole, Gozo, Malta"}}'
CURL

    assert_equal ret['success'], true
    assert_equal ret['error'], []
    assert_equal ret['result']['user_id'], @user_id
    assert_equal ret['result']['duration'], 90
    assert_equal ret['result']['maxdepth'], 40.0
    dive_url = ret['result']['fullpermalink']
    spot_id = ret['result']['spot_id']



    puts "=================================================\n"
    puts "Checking the spot details"
    ret = make_system_call <<CURL
      curl -s "#{@root_url}/api/V2/spot/#{spot_id}"
      -F 'auth_token=#{@auth_token}'
      -F "apikey=#{@api_key}"
CURL

    assert_equal ret['success'], true
    assert_equal ret['error'], []
    assert_equal ret['result']['id'], spot_id
    assert !ret['result']['country_code'].nil?


    # Checking the web page for the dive
    page = Net::HTTP.get_response(URI.parse(dive_url))
    assert_equal page.code, "200"
    assert page.body.match(/2011-10-16 - 09:40/)


  end


end
