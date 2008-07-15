#!/usr/bin/env ruby

require "#{File.dirname(__FILE__)}/test_helper"

class SpiderTest < ActionController::IntegrationTest
  include Caboose::SpiderIntegrator

  def test_standard_user
    sign_in_as people(:peter)
    spider(
      @response.body,
      '/search?browse=true',
      :verbose => true,
      :ignore_urls => %w(/session/new /publications.xml?code=bla3),
      :ignore_forms => %w(/verses)
    )
  end
  
  def test_admin_user
    sign_in_as people(:tim)
    spider(
      @response.body,
      '/search?browse=true',
      :verbose => true,
      :ignore_urls => %w(/session/new /publications.xml?code=bla3 /admin/dashboard/log),
      :ignore_forms => ['/verses', /^\/groups\/\d+\/memberships/]
    )
  end
end
