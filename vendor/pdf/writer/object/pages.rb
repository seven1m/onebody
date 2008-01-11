#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: pages.rb,v 1.2 2005/05/16 03:59:21 austin Exp $
#++
  # object which is a parent to the pages in the document
class PDF::Writer::Object::Pages < PDF::Writer::Object
  def initialize(parent)
    super(parent)

    @parent.catalog.pages = self

    @pages      = []
    @procset    = nil
    @media_box  = nil
    @fonts      = []
    @xObjects   = []
    @bleed_box  = nil
    @trim_box   = nil
  end

  def size
    @pages.size
  end

  def first_page
    @pages[0]
  end

    # Add the page ID to the end of the page list.
  def <<(p)
    if p.kind_of?(PDF::Writer::Object::Page)
      @pages << p
    elsif p.kind_of?(PDF::Writer::Object::Font)
      @fonts << p
    elsif p.kind_of?(PDF::Writer::External)
      @xObjects << p
    else
      raise ArgumentError, PDF::Message[:req_FPXO]
    end
  end

    # Add a page to the page list. If p is just a Page, then it will be
    # added to the page list. Otherwise, it will be treated as a Hash with
    # keys :page, :pos, and :rpage. :page is the Page to be added to the
    # list; :pos is :before or :after; :rpage is the Page to which the
    # new Page will be added relative to.
  def add(p)
    if p.kind_of?(PDF::Writer::Object::Page)
      @pages << p
    elsif p.kind_of?(PDF::Writer::FontMetrics)
      @fonts << p
    elsif p.kind_of?(PDF::Writer::External)
      @xObjects << p
    elsif p.kind_of?(Hash)
      # Find a match.
      i = @pages.index(p[:rpage])
      unless i.nil?
        # There is a match; insert the page.
        case p[:pos]
        when :before
          @pages[i, 0] = p[:page]
        when :after
          @pages[i + 1, 0] = p[:page]
        else
          raise ArgumentError, PDF::Message[:invalid_pos]
        end
      end
    else
      raise ArgumentError, PDF::Message[:req_FPXOH]
    end
  end

  attr_accessor :procset
    # Each of the following should be an array of 4 numbers, the x and y
    # coordinates of the lower left and upper right bounds of the box.
  attr_accessor :media_box
  attr_accessor :bleed_box
  attr_accessor :trim_box

  def to_s
    unless @pages.empty?
      res = "\n#{@oid} 0 obj\n<< /Type /Pages\n/Kids ["
      @pages.uniq! # uniqify the data...
      @pages.each { |p| res << "#{p.oid} 0 R\n" }
      res << "]\n/Count #{@pages.size}"
      unless @fonts.empty? and @procset.nil?
        res << "\n/Resources <<"
        res << "\n/ProcSet #{@procset.oid} 0 R" unless @procset.nil?
        unless @fonts.empty?
          res << "\n/Font << "
          @fonts.each { |f| res << "\n/F#{f.font_id} #{f.oid} 0 R" }
          res << " >>"
        end
        unless @xObjects.empty?
          res << "\n/XObject << "
          @xObjects.each { |x| res << "\n/#{x.label} #{x.oid} 0 R" }
          res << " >>"
        end
        res << "\n>>"
        res << "\n/MediaBox [#{@media_box.join(' ')}]" unless @media_box.nil? or @media_box.empty?
        res << "\n/BleedBox [#{@bleed_box.join(' ')}]" unless @bleed_box.nil? or @bleed_box.empty?
        res << "\n/TrimBox [#{@trim_box.join(' ')}]" unless @trim_box.nil? or @trim_box.empty?
      end
      res << "\n >>\nendobj"
    else
      "\n#{@oid} 0 obj\n<< /Type /Pages\n/Count 0\n>>\nendobj"
    end
  end
end
