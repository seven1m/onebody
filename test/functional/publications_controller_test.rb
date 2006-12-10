require File.dirname(__FILE__) + '/../test_helper'
require 'publications_controller'

# Re-raise errors caught by the controller.
class PublicationsController; def rescue_action(e) raise e end; end

class PublicationsControllerTest < Test::Unit::TestCase
  def setup
    @controller = PublicationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
