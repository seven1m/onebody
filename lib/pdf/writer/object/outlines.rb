#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: outlines.rb,v 1.2 2005/05/16 03:59:21 austin Exp $
#++
  # Define the outlines in the doc, empty for now
class PDF::Writer::Object::Outlines < PDF::Writer::Object
  def initialize(parent)
    super(parent)

    @list = []
    @parent.catalog.outlines = self
  end

  attr_reader :list

  def to_s
    if @list.empty?
      "\n#{@oid} 0 obj\n<< /Type /Outlines >>\nendobj"
    else
      "\n#{@oid} 0 obj\n<< /Type /Outlines /First #{@list[0].oid} 0 R /Last
      #{@list[-1].oid} 0 R>>\nendobj"
    end
  end
end
