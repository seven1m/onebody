#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: state.rb,v 1.2 2005/05/16 03:59:21 austin Exp $
#++
class PDF::Writer
  class State
    attr_accessor :fill_color
    attr_accessor :stroke_color
    attr_accessor :text_render_style
    attr_accessor :stroke_style

    def initialize(vals = {})
      @fill_color         = vals[:fill_color]
      @stroke_color       = vals[:stroke_color]
      @text_render_style  = vals[:text_render_style]
      @stroke_style       = vals[:stroke_style]

      yield self if block_given?
    end

    def blank?
      @fill_color.nil? and @stroke_color.nil? and @stroke_style.nil?
    end
  end

  class StateStack < ::Array
    alias_method :__push__, :push
#   alias_method :__pop__, :pop

    def push(obj)
      return self if obj.nil?
      raise TypeError unless obj.kind_of?(PDF::Writer::State)
      return self if obj.blank?
      __push__(obj)
    end

#   def pop
#     ret = __pop__
#     ret
#   end
  end
end
