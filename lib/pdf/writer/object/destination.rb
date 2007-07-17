#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: destination.rb,v 1.2 2005/05/16 03:59:21 austin Exp $
#++
  # Destination object, used to specify the location for the user to jump
  # to; presently, only on opening.
class PDF::Writer::Object::Destination < PDF::Writer::Object
  def initialize(parent, page, type, *params)
    super(parent)

    case type
    when "FitR"
      raise TypeError if params.size < 4
      @string = "/#{type} #{params[0..3].join(' ')}"
    when "XYZ"
      params = (params + [ "null" ] * 4).first(4)
      @string = "/#{type} #{params[0..2].join(' ')}"
    when "FitH", "FitV", "FitBH", "FitBV"
      raise TypeError if params.empty?
      @string = "/#{type} #{params[0]}"
    when "Fit", "FitB"
      @string = "/#{type}"
    end

    @page = page
  end

  attr_accessor :string
  attr_accessor :page

  def to_s
    "\n#{@oid} 0 obj\n[#{@page.oid} 0 R #{@string}]\nendobj\n"
  end
end
