require File.dirname(__FILE__) + '/test_helper'

class AttrAccessibleIfTest < ActiveSupport::TestCase

  class TestModel < ActiveRecord::Base
    cattr_accessor :enable_hidden
  end
  
  test "original usage of attr_accessible" do
    TestModel.class_eval { attr_accessible :name, :description }
    assert TestModel.accessible_attributes.include?('name')
    assert TestModel.accessible_attributes.include?('description')
  end
  
  test "usage of attr_accessible with 'if' option" do
    TestModel.enable_hidden = true
    TestModel.class_eval { attr_accessible :hidden, :if => Proc.new { TestModel.enable_hidden } }
    assert TestModel.accessible_attributes.include?('hidden')
    assert !TestModel.accessible_attributes.detect { |a| a =~ /^if#<Proc/ }
    TestModel.enable_hidden = false
    assert !TestModel.accessible_attributes.include?('hidden')
  end
  
end

# not sure why this isn't automatic...
if $0 == __FILE__
  require 'test/unit/ui/console/testrunner'
  Test::Unit::UI::Console::TestRunner.run(AttrAccessibleIfTest)
end

