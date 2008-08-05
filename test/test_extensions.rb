module TestExtensions
  def should(name, &block)
    if block_given?
      define_method 'test ' + name, &block
    else
      puts "Unimplemented: " + name
    end
  end
end

require 'test/unit'
Test::Unit::TestCase.extend(TestExtensions)
