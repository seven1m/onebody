require File.dirname(__FILE__) + '/../test_helper'
require 'comatose/page'
require 'comatose/page_wrapper'
require 'comatose/processing_context'

class ProcessingContextTest < Test::Unit::TestCase

  fixtures :comatose_pages
  
  def setup
    @root = comatose_page( :home_page ) 
    @binding = Comatose::ProcessingContext.new(@root)
  end

  should "process liquid tags with no filters correctly" do
    result = TextFilters.transform('{{ page.title }}', @binding, :none, :liquid)
    assert_equal 'Home Page', result
  end
  
  should "process erb tags correctly" do
    result = TextFilters.transform('<%= page.title %>', @binding, :none, :erb)
    assert_equal 'Home Page', result
  end

  should "support text translation and processing with ERB" do
    src = 'The title is *<%= title %>*'
    if TextFilters.all.keys.include? 'None'
      assert_equal "The title is *Home Page*", TextFilters.transform(src, @binding, :none, :erb)
    end    
    if TextFilters.all.keys.include? 'Textile'
      assert_equal "<p>The title is <strong>Home Page</strong></p>", TextFilters.transform(src, @binding, :textile, :erb)
    end    
    if TextFilters.all.keys.include? 'Markdown'
      assert_equal "<p>The title is <em>Home Page</em></p>", TextFilters.transform(src, @binding, 'Markdown', :erb)
    end    
    if TextFilters.all.keys.include? 'RDoc'
      assert_equal "<p>\nThe title is *Home Page*\n</p>\n", TextFilters.transform(src, @binding, :rdoc, :erb)
    end
  end
  
  should "support text translation and processing with Liquid" do
    src = 'The title is *{{ page.title }}*'
    assert_equal "The title is *Home Page*", TextFilters.transform(src, @binding, :none, :liquid)
    if TextFilters.all_titles.include? 'Textile'
      assert_equal "<p>The title is <strong>Home Page</strong></p>", TextFilters.transform(src, @binding, :textile, :liquid)
    end    
    if TextFilters.all_titles.include? 'Markdown'
      assert_equal "<p>The title is <em>Home Page</em></p>", TextFilters.transform(src, @binding, :markdown, :liquid)
    end    
    if TextFilters.all_titles.include? 'RDoc'
      assert_equal "<p>\nThe title is *Home Page*\n</p>\n", TextFilters.transform(src, @binding, :rdoc, :liquid)
    end
  end
  
  UNSAFE_PROPS = %w(version position)
  SAFE_PROPS = %w(id full_path uri slug keywords title to_html filter_type author updated_on created_on)
  
  should "allow access to safe properties and methods when processing with ERB" do
    binding = Comatose::ProcessingContext.new( comatose_page(:faq) )
    SAFE_PROPS.each do |prop|
      assert_not_equal '', TextFilters.transform("<%= page.#{prop} %>", binding, :none, :liquid), "on page.#{prop}"
    end
  end
  
  should "prevent access to protected properties and methods when processing with ERB" do
    binding = Comatose::ProcessingContext.new( comatose_page(:faq) )
    UNSAFE_PROPS.each do |prop|
      assert_equal "<%= page.#{prop} %>", TextFilters.transform("<%= page.#{prop} %>", binding, :none, :liquid), "on page.#{prop}"
    end    
  end
  
  should "allow access to safe properties and methods when processing with Liquid" do
    binding = Comatose::ProcessingContext.new( comatose_page(:faq) )
    SAFE_PROPS.each do |prop|
      assert_not_equal '', TextFilters.transform("{{ page.#{prop} }}", binding, :none, :liquid), "on page.#{prop}"
    end
  end
  
  should "prevent access to protected properties and methods when processing with Liquid" do
    binding = Comatose::ProcessingContext.new( comatose_page(:faq) )
    UNSAFE_PROPS.each do |prop|
      assert_equal '', TextFilters.transform("{{ page.#{prop} }}", binding, :none, :liquid), "on page.#{prop}"
    end    
  end
  
  should "allow referenceing of defined ComatoseDrops" do
    Comatose.define_drop "app" do
      def test
        "TEST"
      end
    end
    
    result = TextFilters.transform('{{ app.test }}', @binding, :none, :liquid)
    assert_equal 'TEST', result
    
    result2 = TextFilters.transform('<%= app.test %>', @binding, :none, :erb)
    assert_equal 'TEST', result2
  end
  
  should "let ComatoseDrop errors bubble upward" do
    Comatose.define_drop "broken" do
      def test
        "TEST #{crap}"
      end
    end
    
    assert_raise(RuntimeError) { TextFilters.transform('{{ broken.test }}', @binding, :none, :liquid) }
  end

end
