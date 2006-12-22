require File.dirname(__FILE__) + '/../test_helper'
require 'music_controller'

# Re-raise errors caught by the controller.
class MusicController; def rescue_action(e) raise e end; end

class MusicControllerTest < Test::Unit::TestCase
  def setup
    @controller = MusicController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
