#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: fontencoding.rb,v 1.4 2005/06/28 21:32:17 austin Exp $
#++
  # The font encoding
class PDF::Writer::Object::FontEncoding < PDF::Writer::Object
  def initialize(parent, encoding, differences)
    super(parent)

    @differences  = differences
    @encoding     = encoding
  end

  attr_accessor :differences
  attr_accessor :encoding

  def to_s
    res = "\n#{@oid} 0 obj\n<< /Type /Encoding\n"
    enc = @encoding || 'WinAnsiEncoding'
    res << "/BaseEncoding /#{enc}\n" unless enc == 'none'
    unless @differences.nil? or @differences.empty?
      res << "/Differences \n["
      n = nil
      @differences.keys.sort.each do |k|
          # Cannot make use of consecutive numbering
        res << "\n#{k} " if n.nil? or k != (n + 1)
        res << " /#{@differences[k]}"
        n = k
      end
      res << "\n]"
    end
    res << "\n>>\nendobj"
  end
end
