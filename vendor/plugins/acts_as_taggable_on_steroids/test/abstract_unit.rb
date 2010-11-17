require 'test/unit'

begin
  require File.dirname(__FILE__) + '/../../../../config/environment'
rescue LoadError
  require 'rubygems'
  gem 'activerecord'
  gem 'actionpack'
  require 'active_record'
  require 'action_controller'
end

# Search for fixtures first
fixture_path = File.dirname(__FILE__) + '/fixtures/'
ActiveSupport::Dependencies.load_paths.insert(0, fixture_path)

require "active_record/test_case"
require "active_record/fixtures"

require File.dirname(__FILE__) + '/../lib/acts_as_taggable'
require_dependency File.dirname(__FILE__) + '/../lib/tag_list'
require_dependency File.dirname(__FILE__) + '/../lib/tags_helper'

ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + '/debug.log')
ActiveRecord::Base.configurations = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.establish_connection(ENV['DB'] || 'mysql')

load(File.dirname(__FILE__) + '/schema.rb')

class ActiveSupport::TestCase #:nodoc:
  include ActiveRecord::TestFixtures
  
  self.fixture_path = File.dirname(__FILE__) + "/fixtures/"
  
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
  
  fixtures :all
  
  def assert_equivalent(expected, actual, message = nil)
    if expected.first.is_a?(ActiveRecord::Base)
      assert_equal expected.sort_by(&:id), actual.sort_by(&:id), message
    else
      assert_equal expected.sort, actual.sort, message
    end
  end
  
  def assert_tag_counts(tags, expected_values)
    # Map the tag fixture names to real tag names
    expected_values = expected_values.inject({}) do |hash, (tag, count)|
      hash[tags(tag).name] = count
      hash
    end
    
    tags.each do |tag|
      value = expected_values.delete(tag.name)
      
      assert_not_nil value, "Expected count for #{tag.name} was not provided"
      assert_equal value, tag.count, "Expected value of #{value} for #{tag.name}, but was #{tag.count}"
    end
    
    unless expected_values.empty?
      assert false, "The following tag counts were not present: #{expected_values.inspect}"
    end
  end
  
  def assert_queries(num = 1)
    $query_count = 0
    yield
  ensure
    assert_equal num, $query_count, "#{$query_count} instead of #{num} queries were executed."
  end

  def assert_no_queries(&block)
    assert_queries(0, &block)
  end
  
  # From Rails trunk
  def assert_difference(expressions, difference = 1, message = nil, &block)
    expression_evaluations = [expressions].flatten.collect{|expression| lambda { eval(expression, block.binding) } } 
    
    original_values = expression_evaluations.inject([]) { |memo, expression| memo << expression.call }
    yield
    expression_evaluations.each_with_index do |expression, i|
      assert_equal original_values[i] + difference, expression.call, message
    end
  end
  
  def assert_no_difference(expressions, message = nil, &block)
    assert_difference expressions, 0, message, &block
  end
end

ActiveRecord::Base.connection.class.class_eval do  
  def execute_with_counting(sql, name = nil, &block)
    $query_count ||= 0
    $query_count += 1
    execute_without_counting(sql, name, &block)
  end
  
  alias_method_chain :execute, :counting
end
