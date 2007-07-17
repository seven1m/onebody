#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: action.rb,v 1.5 2005/05/24 22:19:42 austin Exp $
#++
  # An action object, used to link to URLS initially
class PDF::Writer::Object::Action < PDF::Writer::Object
  def initialize(parent, label, type = "URI")
    super(parent)

    @type   = type
    @label  = label
    raise TypeError if @label.nil?
  end

  attr_accessor :type
  attr_accessor :label

  def to_s
    @parent.arc4.prepare(self) if @parent.encrypted?
    res = "\n#{@oid} 0 obj\n<< /Type /Action"
    if @type == :ilink
      res << "\n/S /GoTo\n/D #{@parent.destinations[@label].oid} 0 R"
    elsif @type == 'URI'
      res << "\n/S /URI\n/URI ("
      if @parent.encrypted?
        res << PDF::Writer.escape(@parent.arc4.encrypt(@label))
      else
        res << PDF::Writer.escape(@label)
      end
      res << ")\n"
    end
    res << ">>\nendobj"
  end
end
