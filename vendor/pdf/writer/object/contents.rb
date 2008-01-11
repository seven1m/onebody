#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: contents.rb,v 1.2.2.1 2005/08/25 03:38:06 austin Exp $
#++
  # The contents objects hold all of the content which appears on pages
class PDF::Writer::Object::Contents < PDF::Writer::Object
  def initialize(parent, page = nil)
    super(parent)

    @data = ""
    @info = {}
    @raw = false
    @on_page = nil

    if page.kind_of?(PDF::Writer::Object::Page)
      @on_page = page
    elsif page == :raw
      @raw = true
    end
  end

  attr_reader   :on_page
  attr_accessor :data

  def size
    @data.size
  end

  def each
    @contents.each { |c| yield c }
  end

  def <<(v)
    raise TypeError unless v.kind_of?(PDF::Writer::Object) or v.kind_of?(String)
    @data << v
  end

  def add(a)
    a.each { |k, v| @info[k] = v }
  end

  def to_s
    tmp = @data.dup
    res = "\n#{@oid} 0 obj\n"
    if @raw
      res << tmp
    else
      res << "<<"
      if PDF::Writer::Compression and @parent.compressed?
        res << " /Filter /FlateDecode"
        tmp = Zlib::Deflate.deflate(tmp)
      end
      if (@parent.encrypted?)
        @parent.arc4.prepare(self)
        tmp = @parent.arc4.encrypt(tmp)
      end
      @info.each { |k, v| res << "\n/#{k} #{v}" }
      res << "\n/Length #{tmp.size} >>\nstream\n#{tmp}\nendstream"
    end
    res << "\nendobj\n"
    res
  end
end
