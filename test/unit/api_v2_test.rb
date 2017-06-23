require 'test_helper'

class ApiV2Test < ActiveSupport::TestCase
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

  def generate_test_user
    num = rand(100000)
    vanity = "test_#{num}"
    while User.where(:vanity_url => vanity).count > 0
      num+=1
      vanity = "test_#{num}"
    end
    assert User.where(:vanity_url => vanity).count == 0
    email = rand_email
    user = User.create do |u|
      u.vanity_url = vanity
      u.email = email
      u.password = '58f76202277ab3d93378e44b565f44127802aeb981f4c60244883f23be8c8d444422f58e59405712a84b067f5135e074725879ac414afcef31a096e7c77f10e8iqO8BSd2IYTBgSDMrE9ehQUFQl9sJgNfTnExqbtzBCF9EFpZO4O0DsqMJFypgAVI'
    end
    assert user.id > 0
    assert user.email == email
    assert user.vanity_url == vanity
    return user
  end

  def generate_test_dive(user)
    @context.push "create dive"
    ret = Dive.create_or_update_from_api( { 'maxdepth' => rand(60).to_i, 'duration' => rand(80).to_i, 'time_in' => '2001-01-27 18:00:00', :user_id => user.id}, { :caller => user } )
    @context.push  ret.to_s
    assert ret[:error] == []
    target = ret[:target] rescue nil
    assert !target.nil?
    assert !target.id.nil?
    assert target.id > 0
    return target
  end

  ## this function makes standard tests, but if it's more complicated, then a block should be given to assert what is right
  def can_update_with(object, attr, val, options, &block)
    @context.push  "#{caller.at(0)} - can_update_with '#{attr}': #{val} -- '#{object.class.name}', '#{object.to_json}', '#{options}'"
    ret = object.class.create_or_update_from_api( {'id' => object.id, attr => val }, options )   
    @context.push ret.to_s
    assert ret[:error] == []
    target = ret[:target] rescue nil
    assert !target.nil?
    assert !target.id.nil?
    assert target.id > 0
    @context.push target.send(attr).to_s
    if block then
      yield ret
    else
      new_val = target.send(attr)
      @context.push new_val.class
      if new_val.is_a? Time then
        @context.push " >> #{new_val.to_s} == #{val+' UTC'} "
        assert target.send(attr).to_s == val+" UTC"
      elsif new_val.is_a? Float then
        @context.push " >> #{new_val.to_json} == #{val.to_f} "
        assert target.send(attr) == val.to_f
      elsif new_val.is_a? Fixnum then
        @context.push " >> #{new_val.to_json} == #{val.to_i} "
        assert target.send(attr) == val.to_i
      elsif new_val.is_a?(FalseClass) or new_val.is_a?(TrueClass) then
        @context.push " >> #{new_val} == #{val} "
        assert target.send(attr).to_s == val.to_s
      elsif new_val.is_a?(Array) && val.is_a?(Array)then
        @context.push " >> #{new_val.to_json} == #{val.to_json} "
        assert target.send(attr) == val
      elsif new_val.is_a?(Array) then
        @context.push " >> #{new_val.to_json} == #{val} "
        assert target.send(attr).to_json == val
      else
        @context.push " >> #{target.send(attr)} == #{val}"
        assert target.send(attr) == val
      end
    end
  end

  ## this function makes standard tests, but if it's more complicated, then a block should be given to assert what is right
  def cannot_update_with(object, attr, val, options, &block)
    @context.push  "#{caller.at(0)} - cannot_update_with '#{attr}': #{val} -- '#{object.class.name}', '#{object.to_json}', '#{options}'"
    object.reload
    pre = object.send(attr)
    @context.push " < #{pre} - "
    ret = object.class.create_or_update_from_api( {'id' => object.id, attr => val }, options )   
    @context.push ret.to_s
    assert ret[:error].count > 0
    target = ret[:target] rescue nil
    target.reload
    assert !target.nil?
    assert !target.id.nil?
    assert target.id > 0
    @context.push target.send(attr).to_s
    if block then
      yield ret
    else
      @context.push  " > #{target.send(attr)}"
      assert target.send(attr) == pre
    end
  end

  ###
  ###
  ### Real tests
  ###
  ###
  test "user_update_simple_attrs" do
    @context = []
    user = generate_test_user
    other_user = generate_test_user
    new_email = rand_email

    initial_vanity = user.vanity_url
    cannot_update_with( user,'vanity_url', other_user.vanity_url, {:caller => user})
    cannot_update_with( user,'vanity_url', nil, {:caller => user})
    cannot_update_with( user,'vanity_url', 'api', {:caller => user})
    cannot_update_with( user,'vanity_url', "#{initial_vanity}_bis", {:caller => other_user})
    cannot_update_with( user,'vanity_url', "#{initial_vanity}_bis", {:caller => nil})
    can_update_with( user,'vanity_url', "#{initial_vanity}_bis", {:caller => user})
    can_update_with( user,'vanity_url', initial_vanity, {:caller => user})

    can_update_with( user, 'contact_email', 'b@toto.fr', {:caller => user}) do |ret|
        assert ret[:target].contact_email == user.email
    end
    cannot_update_with( user, 'contact_email', 'b-toto.fr', {:caller => user})
    cannot_update_with( user, 'contact_email', 'c@toto.fr', {:caller => other_user})
    cannot_update_with( user, 'contact_email', 'd@toto.fr', {:caller => nil})
    
    can_update_with( user, 'email', new_email, {:caller => user})
    cannot_update_with( user, 'email', 'b-toto.fr', {:caller => user})
    cannot_update_with( user, 'email', 'c@toto.fr', {:caller => other_user})
    cannot_update_with( user, 'email', 'd@toto.fr', {:caller => nil})
    cannot_update_with( user, 'email', other_user.email, {:caller => user})

    can_update_with( user, 'nickname', 'toto.fr', {:caller => user}) do |ret|
      assert ret[:target].nickname == 'Toto.fr'
    end
    cannot_update_with( user, 'nickname', 'toto2.fr', {:caller => other_user})
    cannot_update_with( user, 'nickname', 'toto3.fr', {:caller => nil})

    can_update_with( user, 'last_name', 'toto.fr', {:caller => user})
    cannot_update_with( user, 'last_name', 'toto2.fr', {:caller => other_user})
    cannot_update_with( user, 'last_name', 'toto3.fr', {:caller => nil})

    can_update_with( user, 'first_name', 'toto.fr', {:caller => user})
    cannot_update_with( user, 'first_name', 'toto2.fr', {:caller => other_user})
    cannot_update_with( user, 'first_name', 'toto3.fr', {:caller => nil})

    can_update_with( user, 'about', 'toto.fr', {:caller => user})
    cannot_update_with( user, 'about', 'toto2.fr', {:caller => other_user})
    cannot_update_with( user, 'about', 'toto3.fr', {:caller => nil})

    can_update_with( user, 'location', 'fr', {:caller => user})
    can_update_with( user, 'location', nil, {:caller => user}) do |ret|
      assert ret[:target].location == 'blank'
    end
    cannot_update_with( user, 'location', 'sylvanie du sud', {:caller => user})
    cannot_update_with( user, 'location', 'fr', {:caller => other_user})
    cannot_update_with( user, 'location', 'fr', {:caller => nil})

    can_update_with( user, 'total_ext_dives', 123, {:caller => user})
    can_update_with( user, 'total_ext_dives', 0, {:caller => user})
    cannot_update_with( user, 'total_ext_dives', 12, {:caller => other_user})
    cannot_update_with( user, 'total_ext_dives', 32, {:caller => nil})

    can_update_with( user, 'dan_data', {'dan' => 'data'}, {:caller => user})
    can_update_with( user, 'dan_data', nil, {:caller => user})
    cannot_update_with( user, 'dan_data', {'dan' => 'data'}, {:caller => other_user})
    cannot_update_with( user, 'dan_data', {'dan' => 'data'}, {:caller => nil})

    setting_string = "{\"units\":{\"distance\":\"Km\",\"weight\":\"Kg\",\"temperature\":\"C\",\"pressure\":\"bar\"},\"opt_in\":true,\"auto_fb_share\":false,\"qualifs\":{\"featured\":[{\"org\":\"CMAS\",\"title\":\"2 stars diver\",\"date\":\"2011-07-26\"},{\"org\":\"PADI\",\"title\":\"Advanced Open Water\",\"date\":\"2011-07-25\"},{\"org\":\"CMAS\",\"title\":\"Nitrox\",\"date\":\"2011-10-17\"}],\"other\":[{\"org\":\"Other\",\"title\":\"Cayman Island Lionfish Culling License\",\"date\":\"2011-11-08\"},{\"org\":\"CMAS\",\"title\":\"1 star\",\"date\":\"2007-06-01\"}]}}"
    can_update_with( user, 'settings', setting_string, {:caller => user})
    can_update_with( user, 'settings', nil, {:caller => user}) do |ret|
      assert ret[:target].settings == '{}'
    end
    can_update_with( user, 'settings', JSON.parse(setting_string) , {:caller => user}) do |ret|
      @context.push JSON.parse(ret[:target].settings).to_s
      @context.push JSON.parse(setting_string).to_s
      @context.push JSON.parse(ret[:target].settings) == JSON.parse(setting_string)
      assert JSON.parse(ret[:target].settings) == JSON.parse(setting_string)
    end
    cannot_update_with( user, 'settings', nil, {:caller => other_user})
    cannot_update_with( user, 'settings', nil, {:caller => nil})
    
  end

  test "user_update_dives" do
    user = generate_test_user
    other_user = generate_test_user

    ## TODO PASCAL CHECK add :maxdepth =>20
    ret = User.create_or_update_from_api( {'id' => user.id, :dives => [{:duration => 33, :maxdepth =>20}] }, :caller => user )   
    assert ret[:error] == [], ret[:error].to_s
    target = ret[:target] rescue nil
    assert !target.nil?, ret.to_s
    assert !target.id.nil?, ret.to_s
    assert target.id > 0, ret.to_s
    dive_id = target.dives.first.id rescue nil
    assert !dive_id.nil?, user.dives.to_s
    assert dive_id > 0, user.dives.to_s
    assert target.dives.first.spot_id = 1

    ## updating the dive individually
    @context = []
    @context.push "user_id: #{user.id}"
    @context.push "dive_id: #{dive_id}"
    dive = Dive.create_or_update_from_api( {'id' => dive_id, 'spot' => {'id'=>32} }, { :caller => user } )
    @context.push dive.to_s
    assert dive[:error] == [], @context.join("\n")
    assert !dive[:target].nil?, @context.join("\n")
    target = dive[:target]
    assert target[:id] == dive_id, @context.join("\n")
    assert target[:user_id] == user.id, @context.join("\n")
    assert target[:spot_id] == 32, @context.join("\n")
    assert target[:duration] == 33, @context.join("\n")
    assert target[:notes].nil?, @context.join("\n")
    assert Dive.find(dive_id).spot.id == 32, @context.join("\n")


    ## other user cannot change the dive indiviually
    @context = []
    @context.push "user_id: #{user.id}"
    @context.push "other_user_id: #{other_user.id}"
    @context.push "dive_id: #{dive_id}"
    prev = Dive.find(dive_id).spot_id
    dive = Dive.create_or_update_from_api( {'id' => dive_id, 'spot' => {'id'=>34}, 'notes' => 'muf'}, { :caller => other_user } )
    @context.push dive.to_s
    assert dive[:error].count == 2, @context.join("\n")
    assert !dive[:target].nil?, @context.join("\n")
    target = dive[:target]
    assert target[:id] == dive_id, @context.join("\n")
    assert target[:user_id] == user.id, @context.join("\n")
    assert target[:spot_id] == prev, @context.join("\n")
    assert target[:duration] == 33, @context.join("\n")
    assert target[:notes].nil?, @context.join("\n")
    assert Dive.find(dive_id).spot.id == prev, @context.join("\n")


    ## updating dive and adding another one
    @context = []
    @context.push "user_id: #{user.id}"
    @context.push "dive_id: #{dive_id}"
    ret = User.create_or_update_from_api( {'id' => user.id, :dives => [{:id => dive_id, :duration => 43, :notes => 'plop'}, {:spot => {'id' => 33}, :notes => 'truc', :duration => 55, :maxdepth =>20}] }, :caller => user )   
    @context.push ret
    assert ret[:error] == [], @context.join("\n")
    target = ret[:target] rescue nil
    @context.push target.dives.to_json
    assert !target.nil?, @context.join("\n")
    assert !target.id.nil?, @context.join("\n")
    assert target.id > 0, @context.join("\n")
    #user has now 2 dives
    assert target.dives.count == 2, @context.join("\n")
    assert target.dives.map(&:id).include? dive_id
    dive_id2 = target.dives.map(&:id).reject{|d| d == dive_id} .last
    @context.push "dive_id2: #{dive_id2}"
    assert !dive_id2.nil?, @context.join("\n")
    assert dive_id2 > 0, @context.join("\n")
    #dives data have been updated
    assert Dive.find(dive_id).spot_id = 32, @context.join("\n")
    assert Dive.find(dive_id).notes = 'plop', @context.join("\n")
    assert Dive.find(dive_id).duration = 43, @context.join("\n")
    assert Dive.find(dive_id2).spot_id = 33, @context.join("\n")
    assert Dive.find(dive_id2).notes = 'truc', @context.join("\n")
    assert Dive.find(dive_id2).duration = 55, @context.join("\n")


    ##removing one dive
    @context = []
    @context.push "user_id: #{user.id}"
    @context.push "dive_id: #{dive_id}"
    ret = User.create_or_update_from_api( {'id' => user.id, :dives => [{:id => dive_id}] }, :caller => user )   
    @context.push ret
    assert ret[:error] == [], @context.join("\n")
    target = ret[:target] rescue nil
    target.reload
    @context.push target.dives.to_json
    assert !target.nil?, @context.join("\n")
    assert !target.id.nil?, @context.join("\n")
    assert target.id > 0, @context.join("\n")
    #only have 1 dive left
    assert target.dives.count == 1, @context.join("\n")
    assert target.dives.map(&:id).include?(dive_id), @context.join("\n")
    #dive 1 has not changed
    assert Dive.find(dive_id).spot_id = 32, @context.join("\n")
    assert Dive.find(dive_id).notes = 'plop', @context.join("\n")
    assert Dive.find(dive_id).duration = 43, @context.join("\n")
    #dive 2 should have been deleted
    Dive.find(dive_id2).save rescue nil
    dive2 = Dive.find(dive_id2).to_json rescue 'a plus'
    @context.push dive2.to_json
    assert dive2 == 'a plus', @context.join("\n")

  end

  test "user_update_gears" do
    ## TODO
    assert true
  end


  test "dive_simple_updates" do
    @context = []
    user = generate_test_user
    other_user = generate_test_user
    @context.push "user_id: #{user.id} - other_user_id: #{other_user.id}"

    dive = generate_test_dive(user)
    dive_id = dive.id

    ### the following test should fail
    #ret = Dive.create_or_update_from_api( { 'maxdepth' => '', 'duration' => 33, 'time_in' => '2001-01-27 18:00:00', :user_id => user.id}, { :caller => other_user } )
    # assert ret[:error].count == 1, @context
    # target = ret[:target] rescue nil
    # assert !target.nil?, @context
    # assert !target.id.nil?, @context
    # assert target.id > 0, @context

    can_update_with(dive, 'duration', 34, { :caller => user } )
    #TODO cannot_update_with(dive, 'duration', nil, { :caller => user } )
    cannot_update_with(dive, 'duration', 22, { :caller => other_user } )
    cannot_update_with(dive, 'duration', 22, { :caller => nil } )

    can_update_with(dive, 'maxdepth', 33, { :caller => user } )
    #TODO cannot_update_with(dive, 'maxdepth', nil, { :caller => user } )
    cannot_update_with(dive, 'maxdepth', 22, { :caller => other_user } )
    cannot_update_with(dive, 'maxdepth', 22, { :caller => nil } )

    can_update_with(dive, 'maxdepth_unit', "m", { :caller => user } )
    can_update_with(dive, 'maxdepth_unit', "ft", { :caller => user } )
    cannot_update_with(dive, 'maxdepth_unit', "lbs", { :caller => user } )
    can_update_with(dive, 'maxdepth_value', 33, { :caller => user } )

    can_update_with(dive, 'time_in', '1999-12-31 23:59:59', { :caller => user } )
    #TODO cannot_update_with(dive, 'time_in', nil, { :caller => user } )
    cannot_update_with(dive, 'time_in', 22, { :caller => other_user } )
    cannot_update_with(dive, 'time_in', 22, { :caller => nil } )

    can_update_with(dive, 'notes', 'hello', { :caller => user } )
    cannot_update_with(dive, 'notes', 'hell', { :caller => other_user } )
    cannot_update_with(dive, 'notes', 'hell', { :caller => nil } )

    can_update_with(dive, 'temp_surface', '32', { :caller => user } )
    can_update_with(dive, 'temp_surface', 33, { :caller => user } )
    #TODO cannot_update_with(dive, 'temp_surface', 'plop', { :caller => user } )
    cannot_update_with(dive, 'temp_surface', 39, { :caller => other_user } )
    cannot_update_with(dive, 'temp_surface', 30, { :caller => nil } )
    can_update_with(dive, 'temp_surface', nil, { :caller => user } )

    can_update_with(dive, 'temp_surface_unit', "C", { :caller => user } )
    can_update_with(dive, 'temp_surface_unit', "F", { :caller => user } )
    cannot_update_with(dive, 'temp_surface_unit', "lbs", { :caller => user } )
    can_update_with(dive, 'temp_surface_value', 33, { :caller => user } )

    can_update_with(dive, 'temp_bottom', '32', { :caller => user } )
    can_update_with(dive, 'temp_bottom', 33, { :caller => user } )
    #TODO cannot_update_with(dive, 'temp_bottom', 'plop', { :caller => user } )
    cannot_update_with(dive, 'temp_bottom', 39, { :caller => other_user } )
    cannot_update_with(dive, 'temp_bottom', 30, { :caller => nil } )
    can_update_with(dive, 'temp_bottom', nil, { :caller => user } )

    can_update_with(dive, 'temp_bottom_unit', "C", { :caller => user } )
    can_update_with(dive, 'temp_bottom_unit', "F", { :caller => user } )
    cannot_update_with(dive, 'temp_bottom_unit', "lbs", { :caller => user } )
    can_update_with(dive, 'temp_bottom_value', 33, { :caller => user } )

    can_update_with(dive, :privacy, '1', { :caller => user } )
    can_update_with(dive, :privacy, '0', { :caller => user } )
    #TODO cannot_update_with(dive, :privacy, 'plop', { :caller => user } )
    cannot_update_with(dive, :privacy, '1', { :caller => other_user } )
    cannot_update_with(dive, :privacy, '1', { :caller => nil } )

    can_update_with(dive, :safetystops, "[[3.04799999536704,\"3\"]]", { :caller => user } )
    can_update_with(dive, :safetystops_unit_value, "[[3.04799999536704,\"3\",\"m\"]]", { :caller => user } )
    cannot_update_with(dive, :safetystops, "[[3.04799999536704,\"3\",\"kg\"]]", { :caller => user } )
    cannot_update_with(dive, :safetystops, nil, { :caller => other_user } )
    cannot_update_with(dive, :safetystops, nil, { :caller => nil } )
    can_update_with(dive, :safetystops, nil, { :caller => user } )

    can_update_with(dive, :favorite, true, { :caller => user } )
    can_update_with(dive, :favorite, 'false', { :caller => user } )
    cannot_update_with(dive, :favorite, 'plop', { :caller => user } )
    cannot_update_with(dive, :favorite, true, { :caller => other_user } )
    cannot_update_with(dive, :favorite, true, { :caller => nil } )

    can_update_with(dive, 'visibility', 'good', { :caller => user } )
    cannot_update_with(dive, 'visibility', 'awesome mate', { :caller => user } )
    cannot_update_with(dive, 'visibility', 'excellent', { :caller => other_user } )
    cannot_update_with(dive, 'visibility', 'bad', { :caller => nil } )
    can_update_with(dive, 'visibility', nil, { :caller => user } )

    can_update_with(dive, 'trip_name', 'good trip', { :caller => user } )
    cannot_update_with(dive, 'trip_name', 'plop2', { :caller => other_user } )
    cannot_update_with(dive, 'trip_name', 'plop 33', { :caller => nil } )
    can_update_with(dive, 'trip_name', nil, { :caller => user } )

    can_update_with(dive, 'water', 'fresh', { :caller => user } )
    cannot_update_with(dive, 'water', 'smoky', { :caller => user } )
    cannot_update_with(dive, 'water', 'salt', { :caller => other_user } )
    cannot_update_with(dive, 'water', 'salt', { :caller => nil } )
    can_update_with(dive, 'water', nil, { :caller => user } )

    can_update_with(dive, 'number', '123', { :caller => user } )
    can_update_with(dive, 'number', 122, { :caller => user } )
    cannot_update_with(dive, 'number', '110', { :caller => other_user } )
    cannot_update_with(dive, 'number', '109', { :caller => nil } )
    can_update_with(dive, 'number', nil, { :caller => user } )

    can_update_with(dive, 'current', 'light', { :caller => user } )
    cannot_update_with(dive, 'current', 'fucking strong', { :caller => user } )
    cannot_update_with(dive, 'current', 'medium', { :caller => other_user } )
    cannot_update_with(dive, 'current', 'medium', { :caller => nil } )
    can_update_with(dive, 'current', nil, { :caller => user } )

    can_update_with(dive, 'divetype', ['training','wreck'] , { :caller => user } )
    can_update_with(dive, 'divetype', 'recreational, cave' , { :caller => user } ) do |ret|
      assert ret[:target].divetype == ['recreational', 'cave']
    end
    cannot_update_with(dive, 'divetype', ['photography'], { :caller => other_user } )
    cannot_update_with(dive, 'divetype', ['skydive'], { :caller => nil } )
    can_update_with(dive, 'divetype', nil, { :caller => user } ) do |ret|
      assert ret[:target].divetype == []
    end

    can_update_with(dive, 'altitude', '123', { :caller => user } )
    can_update_with(dive, 'altitude', -122, { :caller => user } )
    cannot_update_with(dive, 'altitude', '110', { :caller => other_user } )
    cannot_update_with(dive, 'altitude', '109', { :caller => nil } )
    can_update_with(dive, 'altitude', nil, { :caller => user } )
    can_update_with(dive, 'altitude_unit', "m", { :caller => user } )
    can_update_with(dive, 'altitude_unit', "ft", { :caller => user } )
    cannot_update_with(dive, 'altitude_unit', "lbs", { :caller => user } )
    can_update_with(dive, 'altitude_value', 33, { :caller => user } )

    can_update_with(dive, 'weights', '123', { :caller => user } )
    can_update_with(dive, 'weights', 12, { :caller => user } )
    cannot_update_with(dive, 'weights', -122, { :caller => user } )
    cannot_update_with(dive, 'weights', '110', { :caller => other_user } )
    cannot_update_with(dive, 'weights', '109', { :caller => nil } )
    can_update_with(dive, 'weights', nil, { :caller => user } )
    can_update_with(dive, 'weights_unit', "kg", { :caller => user } )
    can_update_with(dive, 'weights_unit', "lbs", { :caller => user } )
    cannot_update_with(dive, 'weights_unit', "m", { :caller => user } )
    can_update_with(dive, 'weights_value', 33, { :caller => user } )

    can_update_with(dive, 'buddies',  "[{\"name\":\"Andreas\",\"email\":\"\"}]" , { :caller => user } ) do |ret|
      assert ret[:target].buddies.length == 1
      assert ret[:target].buddies.first.nickname == 'Andreas'
      assert ret[:target].buddies.first.email.blank?
    end
    can_update_with(dive, 'buddies', "[{\"name\":\"Pascal manchon\",\"email\":\"\",\"picturl\":\"\",\"fb_id\":\"\",\"db_id\":\"48\"}]", { :caller => user } ) do |ret|
      assert ret[:target].buddies.length == 1
      assert ret[:target].buddies.first.class.name == 'User'
      assert ret[:target].buddies.first.id == 48
    end
    cannot_update_with(dive, 'buddies',  "[{\"name\":\"Andreas\",\"email\":\"\"}]" , { :caller => other_user } )
    cannot_update_with(dive, 'buddies',  "[{\"name\":\"Andreas\",\"email\":\"\"}]" , { :caller => nil } )
    can_update_with(dive, 'buddies', nil, { :caller => user } ) do |ret|
      assert ret[:target].buddies.length == 0
    end

    can_update_with(dive, 'dan_data', {'version' => 3, 'some_data' => 'diving'}, { :caller => user } )
    can_update_with(dive, 'dan_data', {'version' => 3, 'some_data' => 'plop', 'frequency' => 123, 'name' => 'john' } , { :caller => user } )
    cannot_update_with(dive, 'dan_data', {'version' => 3, 'some_data' => 'diving'}, { :caller => other_user } )
    cannot_update_with(dive, 'dan_data', {'version' => 3, 'some_data' => 'diving'}, { :caller => nil } )
    can_update_with(dive, 'dan_data', nil, { :caller => user } )

    can_update_with(dive, 'dive_reviews', "{\"bigfish\":5,\"overall\":4,\"difficulty\":3,\"marine\":2,\"wreck\":1}", { :caller => user } ) do |ret|
        assert ret[:target].dive_reviews_api["bigfish"] == 5
        assert ret[:target].dive_reviews_api["overall"] == 4
        assert ret[:target].dive_reviews_api["difficulty"] == 3
        assert ret[:target].dive_reviews_api["marine"] == 2
        assert ret[:target].dive_reviews_api["wreck"] == 1
    end
    cannot_update_with(dive, 'dive_reviews', "{\"overall\":4,\"difficulty\":3,\"marine\":2,\"wreck\":1}", { :caller => other_user } )
    cannot_update_with(dive, 'dive_reviews', "{\"overall\":4,\"difficulty\":3,\"marine\":2,\"wreck\":1}", { :caller => nil } )



    #Let's find an existing profile that has more than 2 dives in it
    profile_id = nil
    UploadedProfile.all.reverse.each do |profile|
      begin
        log = Divelog.new
        log.from_uploaded_profiles profile.id
        next if log.dives.count < 3
        next if log.dives[0]['sample'].count < 3
        next if log.dives[1]['sample'].count < 3
        profile_id = profile.id
        break
      rescue
        @context.push $!
      end
    end

    assert !profile_id.nil?, "What, you don't have any profile uploaded ???"
    
    can_update_with(dive, 'profile_ref', "#{profile_id},0", { :caller => user } ) 
    assert dive.raw_profile.count > 2
    cannot_update_with(dive, 'profile_ref', "#{profile_id},9999", { :caller => user } )
    cannot_update_with(dive, 'profile_ref', "0,0", { :caller => user } )
    can_update_with(dive, 'profile_ref', "#{profile_id},1", { :caller => user } )
    assert dive.raw_profile.count > 2
    cannot_update_with(dive, 'profile_ref', "#{profile_id},0", { :caller => other_user } )
    cannot_update_with(dive, 'profile_ref', "#{profile_id},0", { :caller => nil } )
    can_update_with(dive, 'profile_ref', nil, { :caller => user } )
    assert dive.raw_profile.count == 0


    tank_id = nil
    tank_id2 = nil
    can_update_with(dive, 'tanks', [ { 'p_start' => 200, 'p_end' => 60, 'o2' => 21, 'n2' => 79, 'material' => 'steel', 'gas' => 'air' } ], { :caller => user } ) do |ret|
      target = ret[:target]
      tank_id = target.tanks.first.id
      assert !tank_id.nil?
      assert target.tanks.first.p_start == 200
      assert target.tanks.first.p_end == 60
      assert target.tanks.first.o2 == 21
      assert target.tanks.first.n2 == 79
      assert target.tanks.first.gas == 'air'
      assert target.tanks.first.material == 'steel'
    end

    can_update_with(Tank.find(tank_id), 'volume', 12, { :caller => user })
    cannot_update_with(Tank.find(tank_id), 'volume', 13, { :caller => other_user })
    cannot_update_with(Tank.find(tank_id), 'volume', 14, { :caller => nil })

    can_update_with(Tank.find(tank_id), 'volume_unit', "L", { :caller => user } )
    can_update_with(Tank.find(tank_id), 'volume_unit', "cuft", { :caller => user } )
    cannot_update_with(Tank.find(tank_id), 'volume_unit', "kg", { :caller => user } )
    can_update_with(Tank.find(tank_id), 'volume_value', 33, { :caller => user } )
    can_update_with(Tank.find(tank_id), 'volume_value', 12, { :caller => user } )
    can_update_with(Tank.find(tank_id), 'volume_unit', "L", { :caller => user } )


    can_update_with(Tank.find(tank_id), 'p_start_unit', "bar", { :caller => user } )
    can_update_with(Tank.find(tank_id), 'p_start_unit', "psi", { :caller => user } )
    cannot_update_with(Tank.find(tank_id), 'p_start_unit', "kg", { :caller => user } )
    can_update_with(Tank.find(tank_id), 'p_start_value', 33, { :caller => user } )
    can_update_with(Tank.find(tank_id), 'p_start_value', 200, { :caller => user } )
    can_update_with(Tank.find(tank_id), 'p_start_unit', "bar", { :caller => user } )



    can_update_with(Tank.find(tank_id), 'p_end_unit', "bar", { :caller => user } )
    can_update_with(Tank.find(tank_id), 'p_end_unit', "psi", { :caller => user } )
    cannot_update_with(Tank.find(tank_id), 'p_end_unit', "kg", { :caller => user } )
    can_update_with(Tank.find(tank_id), 'p_end_value', 33, { :caller => user } )
    can_update_with(Tank.find(tank_id), 'p_end_value', 60, { :caller => user } )
    can_update_with(Tank.find(tank_id), 'p_end_unit', "bar", { :caller => user } )


    can_update_with(dive, 'tanks', [ {'id' => tank_id}, { 'p_start' => 300, 'p_end' => 70, 'o2' => 35, 'n2' => 65, 'material' => 'steel', 'gas' => 'air' } ], { :caller => user } ) do |ret|
      target = ret[:target]
      assert target.tanks.count == 2
      assert target.tanks.map(&:id).include? tank_id
      tank1 = target.tanks.reject {|t| t.id != tank_id} .first
      tank2 = target.tanks.reject {|t| t.id == tank_id} .first
      assert !tank1.nil?
      assert !tank2.nil?
      assert tank1.p_start == 200
      assert tank1.p_end == 60
      assert tank1.o2 == 21
      assert tank1.n2 == 79
      assert tank1.gas == 'air'
      assert tank1.material == 'steel'
      assert tank1.volume == 12
      assert tank2.p_start == 300
      assert tank2.p_end == 70
      assert tank2.o2 == 35
      assert tank2.n2 == 65
      assert tank2.gas == 'custom'
      assert tank2.gas_type == 'nitrox'
      assert tank2.material == 'steel'
    end
    
    can_update_with(dive, 'notes', 'changing notes', { :caller => user } ) do |ret|
      target = ret[:target]
      assert target.tanks.count == 2
      assert target.tanks.map(&:id).include? tank_id
      tank1 = target.tanks.reject {|t| t.id != tank_id} .first
      tank2 = target.tanks.reject {|t| t.id == tank_id} .first
      tank_id2 = tank2.id
      assert !tank2.id.nil?
      assert tank1.p_start == 200
      assert tank1.p_end == 60
      assert tank1.o2 == 21
      assert tank1.n2 == 79
      assert tank1.gas == 'air'
      assert tank1.material == 'steel'
      assert tank1.volume == 12
      assert tank2.p_start == 300
      assert tank2.p_end == 70
      assert tank2.o2 == 35
      assert tank2.n2 == 65
      assert tank2.gas == 'custom'
      assert tank2.material == 'steel'
    end
    cannot_update_with(dive, 'tanks', [ { 'id' => tank_id2 } ], { :caller => other_user } )
    cannot_update_with(dive, 'tanks', [ { 'id' => tank_id2 } ], { :caller => nil } )
    assert dive.tanks.count == 2
    can_update_with(dive, 'tanks', [ { 'id' => tank_id2 } ], { :caller => user } ) do |ret|
      target = ret[:target]
      assert target.tanks.count == 1
      assert target.tanks.first.id == tank_id2
      assert target.tanks.first.p_start == 300
      assert target.tanks.first.p_end == 70
      assert target.tanks.first.o2 == 35
      assert target.tanks.first.n2 == 65
      assert target.tanks.first.gas == 'custom'
      assert target.tanks.first.material == 'steel'
    end

    can_update_with(dive, 'species', [ {'id'=>'c-137746'}, {'id'=>'s-211940'}, {'id'=>'s-204488'}, {'id'=>'c-8396'} ], {:caller => user} ) do |ret|
      target = ret[:target]
      assert !target.nil?
      @context.push target.species
      @context.push target.species.count
      assert target.species.length == 4
      #c-137746 becomes s-207917
      assert target.species.reject {|s| s[:id] != 's-207917'} .length == 1
      assert target.species.reject {|s| s[:id] != 's-211940'} .length == 1
      assert target.species.reject {|s| s[:id] != 's-204488'} .length == 1
      # c-8396 becomes s-2315
      assert target.species.reject {|s| s[:id] != 's-2315'} .length == 1
    end
    can_update_with(dive, 'species', nil, {:caller => user} ) do |ret|
      target = ret[:target]
      assert !target.nil?
      assert target.species == []
    end
    cannot_update_with(dive, 'species', [ {'id'=>'c-137746'}, {'id'=>'s-211940'}, {'id'=>'s-204488'}, {'id'=>'c-8396'} ], {:caller => other_user} )
    cannot_update_with(dive, 'species', [ {'id'=>'c-137746'}, {'id'=>'s-211940'}, {'id'=>'s-204488'}, {'id'=>'c-8396'} ], {:caller => nil} )
    cannot_update_with(dive, 'species', [ {'id'=>'s-999137746'} ], {:caller => user} )
    cannot_update_with(dive, 'species', [ {'id'=>'x-137746'} ], {:caller => user} )
    
    ret = Dive.create_or_update_from_api( { 'maxdepth' => '22', 'duration' => 33, 'time_in' => '2001-01-27 18:00:00', :user_id => user.id, :spot => {'id' => 60}}, { :caller => user } )
    @context.push  ret.to_s
    assert ret[:error] == []
    target = ret[:target] rescue nil
    assert !target.nil?
    dive_id2 = target.id
    @context.push "dive_id2: #{dive_id2}"
    assert !dive_id2.nil?

    dive.reload
    old_spot = dive.spot
    new_spot = nil

    cannot_update_with(dive, 'spot', {'name'=>'super spot', 'lat'=> 0.3, 'long' => 0.5, 'zoom' => 3, 'location' => {'id' => 1}, 'region' => {'id' => 1}, 'country_id' => 1, 'moderate_id' => 60}, {:caller => nil })
    cannot_update_with(dive, 'spot', {'name'=>'super spot', 'lat'=> 0.3, 'long' => 0.5, 'zoom' => 3, 'location' => {'id' => 1}, 'region' => {'id' => 1}, 'country_id' => 1, 'moderate_id' => 60}, {:caller => other_user })
    can_update_with(dive, 'spot', {'name'=>'super spot', 'lat'=> 0.3, 'long' => 0.5, 'zoom' => 3, 'location' => {'id' => 1}, 'region' => {'id' => 1}, 'country_id' => 1, 'moderate_id' => 60}, {:caller => user }) do |ret|
      target = ret[:target]
      new_spot = target.spot_id
      assert !new_spot.nil?
      @context.push target.spot.to_json.to_s
      assert target.spot_id != old_spot
      assert target.spot_id != 60
      assert target.spot.name == 'super spot'.titleize
      assert target.spot.lat == 0.3
      assert target.spot.long == 0.5
      assert target.spot.zoom == 6 ## zoom is at least 6 and max 12
      assert target.spot.location_id == 1
      assert target.spot.region_id == 1
      assert target.spot.country_id > 1 ## fixed from close spots
      assert target.spot.moderate_id == 60
      @context.push Dive.find(dive_id2).spot.to_json
      assert Dive.find(dive_id2).spot_id == target.spot_id
    end

    #testing lng attribute to update instead of long
    can_update_with(dive, 'spot', {'name'=>'super spot 4', 'lat'=> 23, 'lng' => 25, 'zoom' => 3, 'location' => {'id' => 1}, 'region' => {'id' => 1}, 'country_id' => 1}, {:caller => user }) do |ret|
      target = ret[:target]
      new_spot = target.spot_id
      assert !new_spot.nil?
      @context.push target.spot.to_json.to_s
      assert target.spot_id != old_spot
      assert target.spot_id != 60
      assert target.spot.name == 'super spot 4'.titleize
      assert target.spot.lat == 23
      assert target.spot.long == 25
      assert target.spot.zoom == 6 ## zoom is at least 6 and max 12
      assert target.spot.location_id == 1
      assert target.spot.region_id == 1
      assert target.spot.country_id > 1 ## country has been assigned
      assert target.spot.moderate_id.nil?
    end


    cannot_update_with(dive, 'spot', {'id' => new_spot, 'name'=>'super spot 3', 'lat'=> 3.3, 'long' => 3.5, 'zoom' => 4, 'location' => {'id' => 2}, 'region' => {'id' => 2}, 'country_id' => 2}, {:caller => user })

    @context = []
    gear_id1 = nil
    can_update_with(dive, 'dive_gears', [ { 'manufacturer' => 'mares', 'category' => 'Dry suit' } ], {:caller => user} ) do |ret|
      target = ret[:target]
      assert !target.nil?
      assert target.dive_gears.count == 1
      assert target.dive_gears.first.manufacturer == 'mares'
      assert target.dive_gears.first.category == 'Dry suit'
      assert target.dive_gears.first.featured == false
      gear_id1 = target.dive_gears.first.id
      assert !target.dive_gears.first.id.nil?
    end
    can_update_with(dive, 'dive_gears', [ { 'id' => gear_id1, 'category' => 'BCD', 'model' => 'voyager', 'featured' => true } ], {:caller => user} ) do |ret|
      target = ret[:target]
      assert !target.nil?
      assert target.dive_gears.count == 1
      assert target.dive_gears.first.manufacturer == 'mares'
      assert target.dive_gears.first.category == 'BCD'
      assert target.dive_gears.first.model == 'voyager'
      assert target.dive_gears.first.featured == true
      assert target.dive_gears.first.id == gear_id1
    end
    can_update_with(dive, 'dive_gears', [ ], {:caller => user} ) do |ret|
      target = ret[:target]
      assert !target.nil?
      assert target.dive_gears == []
    end
    cannot_update_with(dive, 'dive_gears', [ { 'category' => 'Duck buoy' } ], {:caller => user} ) 
    cannot_update_with(dive, 'dive_gears', [ { 'manufacturer' => 'mares', 'category' => 'Dry suit' } ], {:caller => other_user} ) 
    cannot_update_with(dive, 'dive_gears', [ { 'manufacturer' => 'mares', 'category' => 'Dry suit' } ], {:caller => nil} ) 

    ##FOR user_gears, the user_id need to be given.....
    can_update_with(dive, 'user_gears', [ { 'category' => 'BCD', 'model' => 'voyager', 'user_id' => user.id, 'featured' => true } ], {:caller => user} ) do |ret|
      target = ret[:target]
      target.reload
      assert !target.nil?
      assert target.user_gears.count == 1
      assert target.user_gears.first.user_id == user.id
      assert target.user_gears.first.category == 'BCD'
      assert target.user_gears.first.model == 'voyager'
      assert target.user_gears.first.featured == true
    end
    can_update_with(dive, 'user_gears', [ { 'user_id' => user.id, 'category' => 'Dry suit', 'model' => 'voyager' } ], {:caller => user} ) do |ret|
      target = ret[:target]
      assert !target.nil?
      assert target.user_gears.count == 1
      assert target.user_gears.first.user_id == user.id
      assert target.user_gears.first.category == 'Dry suit'
      assert target.user_gears.first.model == 'voyager'
      assert target.user_gears.first.featured == false
      gear_id1 = target.user_gears.first.id
    end

    dive2 = generate_test_dive(user)
    can_update_with(dive2, 'user_gears', [ { 'id' => gear_id1, 'model' => 'sultan', 'featured' => true } ], {:caller => user} ) do |ret|
      target = ret[:target]
      assert !target.nil?
      assert target.user_gears.count == 1
      assert target.user_gears.first.user_id == user.id
      assert target.user_gears.first.category == 'Dry suit'
      assert target.user_gears.first.model == 'sultan'
      assert target.user_gears.first.featured == true
      assert target.user_gears.first.id == gear_id1

      dive.reload
      assert dive.user_gears.count == 1
      assert dive.user_gears.first.id == gear_id1
      assert dive.user_gears.first.user_id == user.id
      assert dive.user_gears.first.category == 'Dry suit'
      assert dive.user_gears.first.model == 'sultan'
      assert dive.user_gears.first.featured == false
    end

    ##DOC: user_gears => nil cannot be used. user_gears => [] must be used
    cannot_update_with(dive, 'user_gears', [], {:caller => other_user} )
    cannot_update_with(dive, 'user_gears', [], {:caller => nil} )
    can_update_with(dive, 'user_gears', [], {:caller => user} ) do |ret|
      dive.reload
      dive2.reload
      dive.user_gears.count == 0

      assert dive2.user_gears.count == 1
      assert dive2.user_gears.first.user_id == user.id
      assert dive2.user_gears.first.category == 'Dry suit'
      assert dive2.user_gears.first.model == 'sultan'
      assert dive2.user_gears.first.featured == true
      assert dive2.user_gears.first.id == gear_id1
    end

    can_update_with(dive2, 'user_gears', [], {:caller => user} ) do |ret|
      assert ret[:target].user_gears == []
    end
    @context.push UserGear.find(gear_id1)
    assert UserGear.find(gear_id1).user_id == user.id
    assert UserGear.find(gear_id1).category == 'Dry suit'
    assert UserGear.find(gear_id1).model == 'sultan'

    #other user  trying to wear my equipment.... thief !!!!
    other_dive1 = generate_test_dive(other_user)
    cannot_update_with(other_dive1, 'user_gears', [{'id' => gear_id1}], {:caller => other_user} )

    #pictures
    pic1 = Picture.create_image( {:url => 'http://www.flickr.com/photos/61038650@N06/6389140939/in/photostream', :user_id => user.id } )
    pic2 = Picture.create_image( {:url => 'http://www.flickr.com/photos/61038650@N06/6389126711/in/photostream', :user_id => user.id } )
    pic3 = Picture.create_image( {:url => 'http://www.flickr.com/photos/61038650@N06/6389126007/in/photostream', :user_id => user.id } )
    pic_id1 = pic1.id
    pic_id2 = pic2.id
    pic_id3 = pic3.id
    can_update_with(dive, 'pictures', [ {'id' => pic_id1}, {'id'=>pic_id2} ], {:caller => user} ) do |ret|
      target = ret[:target]
      assert target.pictures.count == 2
      assert target.pictures[0].id == pic_id1
      assert target.pictures[1].id == pic_id2
    end
    can_update_with(dive, 'pictures', [ {'id' => pic_id1}, {'id'=>pic_id3} ], {:caller => user} ) do |ret|
      target = ret[:target]
      assert target.pictures[0].id == pic_id1
      assert target.pictures[1].id == pic_id3
    end
    can_update_with(dive, 'pictures', [ ], {:caller => user} ) do |ret|
      target = ret[:target]
      assert target.pictures.count == 0
    end
    cannot_update_with(dive, 'pictures', [{'id' => pic_id1}], {:caller => other_user} ) do |ret|
      target = ret[:target]
      assert target.pictures.count == 0
    end
    cannot_update_with(dive, 'pictures', [{'id' => pic_id1}], {:caller => nil} ) do |ret|
      target = ret[:target]
      assert target.pictures.count == 0
    end

    can_update_with(dive, 'pictures', [{ 'id'=>pic_id1, 'notes'=>'hello world', 'species' => [{'id'=>'c-137746'}, {'id'=>'s-211940'}, {'id'=>'s-204488'}, {'id'=>'c-8396'}] }], {:caller => user} ) do |ret|
      target = ret[:target]
      assert target.pictures.count == 1
      assert target.pictures[0].id == pic_id1
      assert target.pictures.first.notes == 'hello world'
      assert target.pictures.first.species.count == 4
      spid = target.pictures.first.species.map {|s|s[:id]}
      assert spid.include?('c-137746')
      assert spid.include?('c-8396')
      assert spid.include?('s-211940')
      assert spid.include?('s-204488')
    end

    #TODO testing facebook lint page

    #TODO user_id ?????
    real_dan_data = {"version"=>1, "dive"=>{"altitude_date"=>nil, "altitude_exposure"=>6, "altitude_interval"=>nil, "altitude_length"=>nil, "altitude_value"=>nil, "comments"=>nil, "decompression"=>5, "dive_plan"=>2, "dive_plan_table"=>nil, "dress"=>2, "drinks"=>nil, "environment"=>1, "exercice"=>nil, "gases"=>["<1><><0><><63>"], "gases_number"=>1, "hyperbar"=>nil, "hyperbar_location"=>nil, "hyperbar_number"=>nil, "malfunction"=>10, "med_dive"=>nil, "platform"=>2, "problems"=>10, "program"=>nil, "purpose"=>nil, "rest"=>nil, "symptoms"=>2, "thermal_confort"=>1, "workload"=>3, "apparatus"=>1, "bottom_gas"=>"1", "current"=>2}, "diver"=>{"dan_pde_id"=>nil, "license"=>["6666666666", "PADI"], "dan_id"=>nil, "name"=>["Johnsons", "John", nil, nil, nil, nil], "alias"=>nil, "mother"=>nil, "dives_5y"=>21, "dives_12m"=>21, "birthday"=>"19991211", "birthplace"=>[nil, nil, nil], "sex"=>2, "weight"=>["220", "1"], "height"=>["71.5", "1"], "first_certif"=>"20010101", "certif_level"=>2, "conditions"=>nil, "medications"=>nil, "cigarette"=>2, "address"=>["JTF GTMO / JMG", nil, "APO", "AE", "08130", nil], "phone_home"=>["033", "123456789"], "phone_work"=>["033", "12345678"], "email"=>"tototot@diveboard.com", "language"=>"English", "citizenship"=>"USA"}}

    can_update_with(dive, 'dan_data', real_dan_data , { :caller => user } )
    dive.reload
    assert dive.dan_data_sent.nil?
    can_update_with(dive, 'send_to_dan', true, {:caller => user}) do |ret|
      target = ret[:target]
      assert !target.dan_data_sent.nil?
      assert target.dan_data.nil?
      assert target.dan_data_sent == real_dan_data
    end
  end

  test "tanks" do
    assert true
  end

  test "gear" do
    @context = []
    user = generate_test_user
    other_user = generate_test_user
    @context.push "user_id: #{user.id} - other_user_id: #{other_user.id}"

    dive1 = generate_test_dive(user)
    dive2 = generate_test_dive(user)
    other_dive1 = generate_test_dive(other_user)

    #user_gear1 = UserGear.create_or_update_from_api( { 'manufacturer' => 'Mares', 'model' => 'icon hd' }, {:caller => user})


    assert true
  end

  test "picture" do
    assert true
  end

  test "location" do
    ## can create a new location

    ## cannot update a location

  end


  test "spot" do
    @context = []
    user = generate_test_user
    @context.push "user_id: #{user.id}"
    spot_name = rand_name
    location_name = rand_name
    region_name = rand_name
    spot_country_id = 33
    new_spot_id = nil
    new_region_id = nil
    new_location_id = nil
    @context.push "spot name #{spot_name} - location #{location_name} - region #{region_name} - country_id #{spot_country_id}"


    dive = generate_test_dive(user)
    can_update_with(dive, 'spot', { 'name' => spot_name,
                                    'lat' => 1.23,
                                    'long' => 12.8,
                                    'zoom' => 9,
                                    'country_id' => spot_country_id,  
                                    'location' => {'name' => location_name, "country_id" => spot_country_id},
                                    'region' => {'name' => region_name}
                                  }, {:caller => user}) do |ret|
      target = ret[:target]
      new_spot_id = target.spot.id
      new_region_id = target.spot.region.id
      new_location_id = target.spot.location.id
      @context.push "dive with spot #{new_spot_id}, region #{new_region_id}, location #{new_location_id}"
    end
    ##we cannot update exixting location or region
    can_update_with(dive, 'spot', {'name' => spot_name,
                                   'lat' => 1.23,
                                   'long' => 12.8,
                                   'zoom' => 9,
                                   'country_id' => spot_country_id, 
                                   'region' => {'id' => new_region_id},
                                   'location' => {'id' => new_location_id}
                                  }, {:caller => user}) do |ret|
      target = ret[:target]
      assert target.spot.id == new_spot_id
    end
    ##we cannot update exixting location or region
    cannot_update_with(dive, 'spot', {'name' => spot_name,
                                   'lat' => 1.23,
                                   'long' => 12.8,
                                   'zoom' => 9,
                                   'country_id' => spot_country_id, 
                                   'location' => {'id' => new_location_id, 'name' => 'toto', "country_id" => spot_country_id},
                                   'region' => {'id' => new_region_id}
                                  }, {:caller => user}) do |ret|
      target = ret[:target]
      @context.push "spot #{target.spot.id} with same location #{target.spot.location.id} and region #{target.spot.region.id}"
      assert target.spot.id == new_spot_id
    end
    ##region can't be updated, so we create a spot without region
    cannot_update_with(dive, 'spot', {'name' => spot_name,
                                   'lat' => 1.23,
                                   'long' => 12.8,
                                   'zoom' => 9,
                                   'country_id' => spot_country_id,
                                   'location' => {'id' => new_location_id},
                                   'region' => {'id' => new_region_id, 'name' => 'toto'}
                                  }, {:caller => user}) do |ret|
      target = ret[:target]
      @context.push "spot #{target.spot.id} with same location #{target.spot.location.id}"
      assert target.spot.id == new_spot_id ## region sould 
    end

    ## if create a new spot / location / region with same data, same is used
    can_update_with(dive, 'spot', { 'name' => spot_name,
                                    'lat' => 1.23,
                                    'long' => 12.8,
                                    'zoom' => 9, 
                                    'country_id' => spot_country_id, 
                                    'location' => {'name' => location_name, "country_id" => spot_country_id},
                                    'region' => {'name' => region_name}
                                  }, {:caller => user}) do |ret|
      target = ret[:target]    
      assert target.spot.location.id == new_location_id
      assert target.spot.region_id == new_region_id
      assert target.spot.id == new_spot_id
    end
    ##but if there's a diffrerence it makes a new one right ?
    can_update_with(dive, 'spot', { 'name' => spot_name,
                                    'lat' => 1.23,
                                    'long' => 13.8,
                                    'zoom' => 9, 
                                    'country_id' => spot_country_id, 
                                    'location' => {'name' => location_name, "country_id" => spot_country_id},
                                    'region' => {'name' => region_name}
                                  }, {:caller => user})do |ret|
      target = ret[:target]    
      assert target.spot.location.id == new_location_id
      assert target.spot.region_id == new_region_id
      assert target.spot.id != new_spot_id
    end    

    can_update_with(dive, 'spot', { 'name' => spot_name,
                                    'lat' => 1.23,
                                    'long' => 12.8,
                                    'zoom' => 9, 
                                    'country_id' => spot_country_id, 
                                    'location' => {'name' => location_name+"plop", "country_id" => spot_country_id},
                                    'region' => {'name' => region_name}
                                  }, {:caller => user})   do |ret|
      target = ret[:target]    
      assert target.spot.location.id != new_location_id
      assert target.spot.region_id == new_region_id
      assert target.spot.id != new_spot_id
    end 

    can_update_with(dive, 'spot', { 'name' => spot_name,
                                    'lat' => 1.23,
                                    'long' => 12.8,
                                    'zoom' => 9, 
                                    'country_id' => spot_country_id, 
                                    'location' => {'name' => location_name, "country_id" => spot_country_id},
                                    'region' => {'name' => region_name+"waza"}
                                  }, {:caller => user})    do |ret|
      target = ret[:target]    
      assert target.spot.location.id == new_location_id
      assert target.spot.region_id != new_region_id
      assert target.spot.id != new_spot_id
    end

    assert true
  end


  test "shop" do
    @context = []
    user = generate_test_user
    other_user = generate_test_user
    @context.push "user_id: #{user.id} - other_user_id: #{other_user.id}"

    dive = generate_test_dive(user)
    can_update_with(dive, 'diveshop', {'name' => 'johns diving'}, { :caller => user } ) do |ret|
        assert ret[:target].shop.name == 'johns diving'
    end
    can_update_with(dive, 'diveshop', {'name' => 'marks diving', 'url' => 'http://toto.fr' } , { :caller => user } ) do |ret|
        assert ret[:target].shop.name == 'marks diving'
        assert ret[:target].shop.url == 'http://toto.fr'
    end
    cannot_update_with(dive, 'diveshop', {'name' => 'johns diving'}, { :caller => other_user } )
    cannot_update_with(dive, 'diveshop', {'name' => 'johns diving'}, { :caller => nil } )
    can_update_with(dive, 'diveshop', nil, { :caller => user } )

    can_update_with(dive, 'shop', {'id' => 711}, { :caller => user } ) do |ret|
      target = ret[:target]
      assert !target.shop.nil?
      assert target.shop.id == 711
    end
    can_update_with(dive, 'shop', {'id' => 999}, { :caller => user } ) do |ret|
      target = ret[:target]
      assert !target.shop.nil?
      assert target.shop.id == 999
    end
    cannot_update_with(dive, 'shop', {'id' => 711}, { :caller => other_user } ) do |ret|
      target = ret[:target]
      assert !target.shop.nil?
      assert target.shop.id == 999
    end
    cannot_update_with(dive, 'shop', {'id' => 711}, { :caller => nil } ) do |ret|
      target = ret[:target]
      assert !target.shop.nil?
      assert target.shop.id == 999
    end
    can_update_with(dive, 'shop', nil, { :caller => user } ) do |ret|
      target = ret[:target]
      assert target.shop.nil?
    end

    can_update_with(dive, 'guide', 'john', { :caller => user } )
    can_update_with(dive, 'guide', 'jack', { :caller => user } )
    cannot_update_with(dive, 'guide', 'john', { :caller => other_user } )
    cannot_update_with(dive, 'guide', 'john', { :caller => nil } )
    can_update_with(dive, 'guide', nil, { :caller => user } )

    #testing generation of legacy diveshop hash
    can_update_with(dive, 'diveshop', {'name' => 'marks diving', 'url' => 'http://toto.fr' } , { :caller => user } ) do |ret|
        assert ret[:target].shop.name == 'marks diving'
        assert ret[:target].shop.url == 'http://toto.fr'
    end
    can_update_with(dive, 'guide', 'john', { :caller => user } )
    dive.reload
    assert dive.diveshop['guide'] == 'john'
    assert dive.diveshop['name'] == 'marks diving'
    assert dive.diveshop['url'] == 'http://toto.fr'
    ##assert !dive.diveshop.include?('id') << We need the id .... without the id it's creating a new shop at every save

    can_update_with(dive, 'shop', {'id' => 711}, { :caller => user } ) do |ret|
      target = ret[:target]
      assert !target.shop.nil?
      assert target.shop.id == 711
    end
    assert dive.diveshop['guide'] == 'john'
    assert dive.diveshop['name'] == 'marks diving'
    assert dive.diveshop['url'] == 'http://toto.fr'
    ##assert !dive.diveshop.include?('id') << We need the id .... without the id it's creating a new shop at every save
  end

  test "spot_search" do
   assert SearchHelper.spot_text_search(nil, "").empty?
   assert SearchHelper.spot_text_search(nil, "qwertyuiiopp").empty?
   assert SearchHelper.spot_text_search(nil, 'Fourth Window (United States - Florida West Palm Beach)').first.name == "Fourth Window"
   assert !(SearchHelper.spot_text_search(nil, 'hurghada').first.location.name.match(/hurghada/i).nil?)
   assert !(SearchHelper.spot_text_search(nil, 'river').first.location.name.match(/river/i).nil?)
   assert !(SearchHelper.spot_text_search(nil, 'bay').first.location.name.match(/bay/i).nil? && SearchHelper.spot_text_search(nil, 'bay').first.name.match(/bay/i).nil?)
   assert !(SearchHelper.spot_text_search(nil, 'island').first.location.name.match(/island/i).nil?)
   #assert !(SearchHelper.spot_text_search(nil, 'red').first.region.name.match(/red\ sea/i).nil?)
   assert !(SearchHelper.spot_text_search(nil, 'red se').first.region.name.match(/red\ sea/i).nil?)
   assert !(SearchHelper.spot_text_search(nil, 'red sea').first.region.name.match(/red\ sea/i).nil?)
   assert SearchHelper.spot_text_search(nil, 'blu go ho').map(&:name).include?("Blue Hole")
   assert SearchHelper.spot_text_search(nil, 'blue hole').map(&:name).include?("Blue Hole")
   assert SearchHelper.spot_text_search(nil, '~!@#$%^&*()_+<>?","~!@#$%^&*()_+<>?').empty?
   assert !(SearchHelper.spot_text_search(nil, "(Malta - Gozo)").first.country.cname.match(/malta/i).nil?)
  end

  test "new_dive_with_profile" do
    @context = []
    user = generate_test_user
    ret = Dive.create_or_update_from_api({'user_id' => user.id, 'raw_profile' => [{'seconds'=> 1, 'depth'=> 2}]}, {:caller => user})
    assert ret[:error] == []
    target = ret[:target]
    assert target.class.name == 'Dive'
    assert target.user_id == user.id
    assert target.raw_profile.length == 1
    assert target.raw_profile.first.seconds == 1
    assert target.raw_profile.first.depth == 2
  end

end
