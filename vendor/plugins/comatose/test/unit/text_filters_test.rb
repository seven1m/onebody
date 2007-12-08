require File.dirname(__FILE__) + '/../test_helper'

require 'erb'
require 'liquid'

require 'text_filters'
# require 'comatose/page'
# require 'comatose/processing_context'

class TextFiltersTest < Test::Unit::TestCase
  # fixtures :comatose_pages
  # self.use_instantiated_fixtures  = true

  should "not alter output when using filter :none" do
    assert_equal "line one\nline two", TextFilters.render_text("line one\nline two", :none)
  end

  should "convert newlines into <br/>s when using :simple filter" do
    assert_equal "line one<br/>line two", TextFilters.render_text("line one\nline two", :simple)
  end

  should "support Textile, if it's available, using :textile or 'Textile' as a key" do
    if TextFilters.all.keys.include? 'Textile'
      assert_equal "<p>testing <strong>bold</strong></p>", TextFilters.render_text("testing *bold*", :textile)
      assert_equal "<p>testing <strong>bold</strong></p>", TextFilters.render_text("testing *bold*", 'Textile')
    end
  end
  
  should "support Markdown, if it's available, using :markdown or 'Markdown' as a key" do
    if TextFilters.all.keys.include? 'Markdown'
      assert_equal "<p>testing <em>bold</em></p>", TextFilters.render_text("testing *bold*", :markdown)
    end
  end

  should "support RDoc, if it's available, using :rdoc or 'RDoc' as a key" do
    if TextFilters.all.keys.include? 'RDoc'
      assert_equal "<p>\ntesting <b>bold</b>\n</p>\n", TextFilters.render_text("testing *bold*", :rdoc)
      assert_equal "<p>\ntesting <b>bold</b>\n</p>\n", TextFilters.render_text("testing *bold*", 'RDoc')
    end
  end

  should "support transformation of parameters via ERB" do
    src = 'Hello, <%= name %>'
    assert_equal "Hello, Matt", TextFilters.transform(src, {'name'=>'Matt'}, :none, :erb)
  end

  should "support transformation of parameters via Liquid" do
    src = 'Hello, {{ name }}'
    assert_equal "Hello, Matt", TextFilters.transform(src, {'name'=>'Matt'}, :none, :liquid)
  end
  
end
