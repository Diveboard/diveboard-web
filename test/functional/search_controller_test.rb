require 'test_helper'

class SearchControllerTest < ActionController::TestCase
  test "should get search" do
    get :search
    assert_response :success
  end

  test "should get spot" do
    get :spot
    assert_response :success
  end

  test "should get diver" do
    get :diver
    assert_response :success
  end

  test "should get fish" do
    get :fish
    assert_response :success
  end

end
