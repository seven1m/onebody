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
      :ignore_urls => %w(/groups/leave/2 /session/new /session),
      :ignore_forms => %w(/verses)
    )
  end
end
