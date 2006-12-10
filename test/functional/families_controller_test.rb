require File.dirname(__FILE__) + '/../test_helper'
require 'families_controller'

# Re-raise errors caught by the controller.
class FamiliesController; def rescue_action(e) raise e end; end

class FamiliesControllerTest < Test::Unit::TestCase
  def setup
    @controller = FamiliesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
