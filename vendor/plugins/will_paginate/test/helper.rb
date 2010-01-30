require 'test/unit'
require 'rubygems'

# gem install redgreen for colored test output
begin require 'redgreen'; rescue LoadError; end

require 'boot' unless defined?(ActiveRecord) || defined?(ActiveResource)

class Test::Unit::TestCase
  protected
  def assert_respond_to_all object, methods
    methods.each do |method|
      [method.to_s, method.to_sym].each { |m| assert_respond_to object, m }
    end
  end
  
  def collect_deprecations
    old_behavior = WillPaginate::Deprecation.behavior
    deprecations = []
    WillPaginate::Deprecation.behavior = Proc.new do |message, callstack|
      deprecations << message
    end
    result = yield
    [result, deprecations]
  ensure
    WillPaginate::Deprecation.behavior = old_behavior
  end
  
  def assert_select_xml(*args, &block)
    @selected ||= HTML::Document.new(args.shift.to_s, false, true).root.children
    assert_select(*args, &block)
  end
end

# Wrap tests that use Mocha and skip if unavailable.
def uses_mocha(test_name)
  unless Object.const_defined?(:Mocha)
    gem 'mocha', '>= 0.9.5'
    require 'mocha'
  end
rescue LoadError => load_error
  $stderr.puts "Skipping #{test_name} tests. `gem install mocha` and try again."
else
  yield
end
