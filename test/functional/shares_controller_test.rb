require File.dirname(__FILE__) + '/../test_helper'
require 'shares_controller'

# Re-raise errors caught by the controller.
class SharesController; def rescue_action(e) raise e end; end

class SharesControllerTest < Test::Unit::TestCase
  def setup
    @controller = SharesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
