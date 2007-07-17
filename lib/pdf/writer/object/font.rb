#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: font.rb,v 1.5 2005/06/28 21:32:17 austin Exp $
#++
  # An object to hold the font description
class PDF::Writer::Object::Font < PDF::Writer::Object
  Details = %w{FirstChar LastChar Widths FontDescriptor SubType}

  def initialize(parent, name, encoding = 'WinAnsiEncoding', subtype = 'Type1')
    super(parent)

    @name     = name
    @subtype  = subtype
    @font_id  = @parent.__send__(:generate_font_id)

    if encoding.kind_of?(PDF::Writer::Object::FontEncoding)
      @encoding           = encoding
    elsif encoding == 'none' or encoding.nil?
      @encoding           = nil
    else
      @encoding           = encoding
    end

    @parent.pages << self

    @firstchar      = nil
    @lastchar       = nil
    @widths         = nil
    @fontdescriptor = nil
  end

  attr_reader :font_id
    # The type of the font: Type1 and TrueType are the only values supported
    # by 
  attr_reader :subtype
    # Valid values: WinAnsiEncoding, MacRomanEncoding, MacExpertEncoding,
    # none, +nil+, or an instance of PDF::Writer::Object::FontEncoding.
  attr_reader :encoding
  attr_reader :basefont
  def basefont #:nodoc:
    @name
  end

  Details.each do |d|
    attr_accessor d.downcase.intern
  end

  def to_s
    res = "\n#{@oid} 0 obj\n<< /Type /Font\n/Subtype /#{@subtype}\n"
    res << "/Name /F#{@font_id}\n/BaseFont /#{@name}\n"
    if @encoding.kind_of?(PDF::Writer::Object::FontEncoding)
      res << "/Encoding #{@encoding.oid} 0 R\n"
    elsif @encoding
      res << "/Encoding /#{@encoding}\n" if @encoding
    end
    res << "/FirstChar #{@firstchar}\n" unless @firstchar.nil?
    res << "/LastChar #{@lastchar}\n" unless @lastchar.nil?
    res << "/Widths #{@widths} 0 R\n" unless @widths.nil?
    res << "/FontDescriptor #{@fontdescriptor} 0 R\n" unless @fontdescriptor.nil?
    res << ">>\nendobj"
  end
end
