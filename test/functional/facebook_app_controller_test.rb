require 'test_helper'

class FacebookAppControllerTest < ActionController::TestCase
  test "should get read" do
    get :read
    assert_response :success
  end

end
