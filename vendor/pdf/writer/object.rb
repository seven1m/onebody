#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: object.rb,v 1.3 2005/05/25 11:19:50 austin Exp $
#++
class PDF::Writer::Object
  def initialize(parent)
    @parent = parent
    @oid    = @parent.__send__(:generate_id)
    @parent.objects << self
  end
      
  attr_reader :oid
end

class PDF::Writer::External < PDF::Writer::Object; end

class PDF::Writer::Complex < PDF::Writer::Object; end
