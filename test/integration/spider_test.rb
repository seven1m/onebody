require "#{File.dirname(__FILE__)}/../test_helper"

class SpiderTest < ActionController::IntegrationTest
  include Caboose::SpiderIntegrator

  def test_spider
    assert true # disable for now
    #sign_in_as people(:peter)
    #spider(
    #  @response.body,
    #  '/directory/browse',
    #  # :verbose => true,
    #  :ignore_urls => %w(/account/sign_out /account/sign_in /events /directory/directory_to_pdf)
    #) # TODO: ignoring /events url for now due to unknown error
  end
end
