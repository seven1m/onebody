$:.unshift File.dirname(__FILE__) + '/../lib/'

require 'rubygems'
require 'active_support'
require 'test/unit'
require 'caboose/spider_integrator'

# These are the tests for some of the spider integrator internal methods.
class TestSpiderIntegrator < Test::Unit::TestCase
  include Caboose::SpiderIntegrator
  
  FakeLink = Struct.new( :attributes )
  
  def setup
    @links_to_visit = []
  end
  
  def test_queue_link_ignores_emails
    results = queue_link(FakeLink.new({ 'href' => 'mailto:joe@test.com' }), nil)
    assert @links_to_visit.empty?
  end
  
  def test_queue_link_follows_regular_links
    results = queue_link(FakeLink.new({ 'href' => '/users/foo/bar' }), nil)
    assert_equal 1, @links_to_visit.size
  end
  
  def test_queue_link_doesnt_follow_external_links
    results = queue_link(FakeLink.new({ 'href' => 'http://google.com/' }), nil)
    assert @links_to_visit.empty?
  end

  def test_queue_link_doesnt_follow_hex_encoded_emails
    results = queue_link(FakeLink.new({ 'href' => '&#109;&#97;&#105;&#108;&#116;&#111;&#58;' }), nil)
    assert @links_to_visit.empty?
  end
  
  
  def test_spider_should_ignore
    setup_spider( :ignore_urls => ['/logout', %r{/.*/delete/.*}], 
                  :ignore_forms => ['/login', %r{.*/destroy/.*}],
                  :verbose => true )
                  
    assert spider_should_ignore_url?('/logout')
    assert spider_should_ignore_url?('/posts/delete/1')
          
    assert spider_should_ignore_form?('/login')
    assert spider_should_ignore_form?('/posts/destroy/1')
  end
  

end