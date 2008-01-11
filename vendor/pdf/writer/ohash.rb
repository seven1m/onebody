#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: ohash.rb,v 1.2 2005/05/16 03:59:21 austin Exp $
#++
  # Based on [ruby-talk:20551]. Updated to (hopefully) be 1.8 friendly.
class PDF::Writer::OHash < Hash
  alias_method :store, :[]=
  alias_method :each_pair, :each

  def initialize(*args)
    @keys = []
    super
  end

  def []=(key, val)
    @keys << key unless has_key?(key)
    super
  end

  def delete(key)
    @keys.delete(key) if has_key?(key)
    super
  end

  def each
    @keys.each { |k| yield k, self[k] }
  end

  def each_key
    @keys.each { |k| yield k }
  end

  def each_value
    @keys.each { |k| yield self[k] }
  end

  def first
    self[@keys[0]]
  end

  def last
    self[@keys[-1]]
  end

  def first?(item)
    self[@keys[0]] == item
  end

  def last?(item)
    self[@keys[-1]] == item
  end
end
