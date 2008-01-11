#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: outline.rb,v 1.2 2005/05/16 03:59:21 austin Exp $
#++
  # Define the outlines in the doc, empty for now
class PDF::Writer::Object::Outline < PDF::Writer::Object
  def initialize(parent, label, title = label)
    super(parent)

    @action = PDF::Writer::Action.new(parent, label, :ilink)
    @title  = title

    parent.outlines.list << self
  end

  def to_s
    pos = @parent.outlines.list.index(self)
    res = "\n#{@oid} 0 obj\n<< /Title (#{@title})"
    res << " /Prev #{@parent.outlines.list[pos - 1].oid} 0 R" if pos.nonzero?
    res << " /Next #{@parent.outlines.list[pos + 1].oid} 0 R" if @oid != parent.outlines.list[-1].oid
    res << " /A #{@action.oid} 0 R>>\nendobj"
    res
  end
end
