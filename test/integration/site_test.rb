require File.dirname(__FILE__) + '/../test_helper'

class SiteTest < ActionController::IntegrationTest

  should "set view_paths based on site template selection" do
    get '/'
    assert_match /themes\/aqueouslight/, assigns(:view_paths).first.to_s
  end

end
