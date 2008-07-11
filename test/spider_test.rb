#!/usr/bin/env ruby

require "#{File.dirname(__FILE__)}/test_helper"

class SpiderTest < ActionController::IntegrationTest
  include Caboose::SpiderIntegrator

  def test_spider
    sign_in_as people(:peter)
    spider(
      @response.body,
      '/search?browse=true',
      :verbose => true,
      :ignore_urls => %w(/account/sign_out /account/sign_in /events /directory/directory_to_pdf /groups/leave/2),
      :ignore_forms => %w(/verses)
    )
  end
end
