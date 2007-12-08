require File.dirname(__FILE__) + '/../test_helper'
require 'support/class_options'

class ClassOptionsTest < Test::Unit::TestCase

  class Opts
    define_option :nothing, nil
    define_option :nada
    define_option :name, "Matt"
    define_option :age, 30
    define_option :mode, :test
    define_option :listing, ['one', 'two', 'three']
    define_option :opts_1, {'one'=>'ONE', 'two'=>'TWO'}
    define_option :opts_2, {:one=>'ONE', :two=>'TWO'}
    define_option :should_work, true
    define_option :would_surprise, false
  end

  should "allow nil as a default" do
    assert_equal nil, Opts.nothing
    assert_equal nil, Opts.nada
  end
  
  should "allow boolean defaults" do
    assert_equal true, Opts.should_work
    assert_equal false, Opts.would_surprise
  end

  should "allow string defaults" do
    assert_equal 'Matt', Opts.name
  end

  should "allow numeric defaults" do
    assert_equal 30, Opts.age
  end

  should "allow symbolic defaults" do
    assert_equal :test, Opts.mode
  end

  should "allow array literals as defaults" do
    assert_equal ['one', 'two', 'three'], Opts.listing
  end

  should "allow hash literals as defaults" do
    h1 = {'one'=>'ONE', 'two'=>'TWO'}
    h2 = {:one=>'ONE', :two=>'TWO'}
    assert_equal h1, Opts.opts_1
    assert_equal h2, Opts.opts_2
  end
  
end
