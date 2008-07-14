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
      :ignore_urls => %w(/groups/2/memberships/5 /groups/2/memberships/3 /session/new /session /publications.xml?code=bla3),
      :ignore_forms => %w(/verses)
    )
  end
end
