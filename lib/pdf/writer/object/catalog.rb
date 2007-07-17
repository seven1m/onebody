#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: catalog.rb,v 1.2 2005/05/16 03:59:21 austin Exp $
#++
  # Define the document catalog, the overall controller for the document
class PDF::Writer::Object::Catalog < PDF::Writer::Object
  def initialize(parent)
    super(parent)

    @outlines           = nil
    @pages              = nil
    @open_here          = nil
    @viewer_preferences  = nil
    @page_mode          = nil
  end

  attr_accessor :outlines
  attr_accessor :pages
  attr_accessor :open_here
  attr_accessor :viewer_preferences
  attr_accessor :page_mode

  def to_s
    res = "\n#{@oid} 0 obj\n<< /Type /Catalog"
    res << "\n/Outlines #{@outlines.oid} 0 R" unless @outlines.nil?
    res << "\n/Pages #{@pages.oid} 0 R" unless @pages.nil?
    res << "\n/ViewerPreferences #{@viewer_preferences.oid} 0 R" if @viewer_preferences and @parent.version >= '1.2'
    res << "\n/OpenAction #{@open_here.oid} 0 R" unless @open_here.nil?
    res << "\n/PageMode /#{@page_mode}" unless @page_mode.nil?
    res << "\n/Version /#{@parent.version}" if @parent.version >= '1.4'
    res << ">>\nendobj"
  end
end
