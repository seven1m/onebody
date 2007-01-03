require File.dirname(__FILE__) + '/../test_helper'
require 'prayer_controller'

# Re-raise errors caught by the controller.
class PrayerController; def rescue_action(e) raise e end; end

class PrayerControllerTest < Test::Unit::TestCase
  def setup
    @controller = PrayerController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
