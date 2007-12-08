require File.dirname(__FILE__) + '/../test_helper'
require 'comatose/controller'

# Re-raise errors caught by the controller.
class ComatoseController < Comatose::Controller
  def rescue_action(e) raise e end
end


class ComatoseControllerTest < Test::Unit::TestCase

  fixtures :comatose_pages

  def setup
    @controller = ComatoseController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_truth
    assert true
  end
  
  should "show pages based on path_info" do

    # Get the faq page...
    get :show, :page=>'faq', :index=>'', :layout=>'comatose_content', :use_cache=>'false'
    assert_response :success
    assert_tag :tag=>'h1', :child=>/Frequently Asked Questions/

    # Get a question page using rails 2.0 array style...
    get :show, :page=>['faq','question-one'], :index=>'', :layout=>'comatose_content', :use_cache=>'false'
    assert_response :success
    assert_tag :tag=>'title', :child=>/Question/

    # Get a question page using rails 1.x path style...
    get :show, :page=>ActionController::Routing::PathSegment::Result.new_escaped(['faq','question-one']), 
        :index=>'', :layout=>'comatose_content', :use_cache=>'false'
    assert_response :success
    assert_tag :tag=>'title', :child=>/Question/
  end

end