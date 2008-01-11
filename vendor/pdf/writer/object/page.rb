#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: page.rb,v 1.3 2005/06/02 21:20:35 austin Exp $
#++
  # A page object, it also creates a contents object to hold its contents
class PDF::Writer::Object::Page < PDF::Writer::Object
    # Create a page. The optional +relative+ is a Hash with keys :pos =>
    # :before|:after and :rpage, the page to which this new page will be
    # added relative.
  def initialize(parent, relative = nil)
    super(parent)

    @parent.current_page = self
    @owner = @parent.instance_variable_get('@current_node')
    @page_number = @parent.pages.size
    @contents = []

    if relative.nil?
      @parent.pages << self
    else
      relative[:page] = self
      @parent.pages.add(relative)
    end

      # make a contents object to go with this page
    @contents << PDF::Writer::Object::Contents.new(@parent, self)
    @parent.instance_variable_set('@current_contents', @contents[-1])
    match = (@parent.pages.size % 2 == 0 ? :even_pages : :odd_pages)
      # Cheat here. I don't want to add an unnecessary attribute.
    @parent.instance_variable_get('@add_loose_objects').each do |obj, target|
      @contents << obj if target == :all_pages or match == target
    end

    @annotations = []

    @media_box  = nil
    @crop_box   = nil
    @bleed_box  = nil
    @trim_box   = nil
    @art_box    = nil
  end

  attr_accessor :contents
  attr_reader :page_number

  def add_annotation(a)
    @annotations << a
  end

  def to_s
    res = "\n#{@oid} 0 obj\n<< /Type /Page\n/Parent #{@owner.oid} 0 R"
    unless @annotations.empty?
      res << "\n/Annots ["
      @annotations.each { |e| res << " #{e.oid} 0 R"}
      res << "]"
    end

    if @contents.size == 1
      res << "\n/Contents #{@contents[0].oid} 0 R"
    else
      res << "\n/Contents [\n"
      @contents.each { |c| res << "#{c.oid} 0 R\n" }
      res << "]"
    end

      # MediaBox::  rectangle (Required; inheritable). A rectangle (see
      #             Section 3.8.4, “Rectangles”), expressed in default user
      #             space units, defining the boundaries of the physical
      #             medium on which the page is intended to be displayed or
      #             printed (see Section 10.10.1, “Page Boundaries”). 
    res << "\n/MediaBox [#{@media_box.join(' ')}]" unless @media_box.nil? or @media_box.empty?
      # CropBox::   rectangle (Optional; inheritable) A rectangle, expressed
      #             in default user space units, defining the visible region
      #             of default user space. When the page is displayed or
      #             printed, its contents are to be clipped (cropped) to
      #             this rectangle and then imposed on the output medium in
      #             some implementation-defined manner (see Section 10.10.1,
      #             “Page Boundaries”). Default value: the value of MediaBox. 
    res << "\n/CropBox [#{@crop_box.join(' ')}]" unless @crop_box.nil? or @crop_box.empty?
      # BleedBox::  rectangle (Optional; PDF 1.3) A rectangle, expressed in
      #             default user space units, defining the region to which
      #             the contents of the page should be clipped when output
      #             in a production environment (see Section 10.10.1, “Page
      #             Boundaries”). Default value: the value of CropBox. 
    res << "\n/BleedBox [#{@bleed_box.join(' ')}]" unless @bleed_box.nil? or @bleed_box.empty?
      # TrimBox::   rectangle (Optional; PDF 1.3) A rectangle, expressed in
      #             default user space units, defining the intended
      #             dimensions of the finished page after trimming (see
      #             Section 10.10.1, “Page Boundaries”). Default value: the
      #             value of CropBox. 
    res << "\n/TrimBox [#{@trim_box.join(' ')}]" unless @trim_box.nil? or @trim_box.empty?
      # ArtBox::    rectangle (Optional; PDF 1.3) A rectangle, expressed in
      #             default user space units, defining the extent of the
      #             page’s meaningful content (including potential white
      #             space) as intended by the page’s creator (see Section
      #             10.10.1, “Page Boundaries”). Default value: the value of
      #             CropBox. 
    res << "\n/ArtBox [#{@art_box.join(' ')}]" unless @art_box.nil? or @art_box.empty?

    res << "\n>>\nendobj"
  end
end

  # BoxColorInfo::  dictionary (Optional; PDF 1.4) A box color information
  #                 dictionary specifying the colors and other visual
  #                 characteristics to be used in displaying guidelines on
  #                 the screen for the various page boundaries (see “Display
  #                 of Page Boundaries” on page 893). If this entry is
  #                 absent, the application should use its own current
  #                 default settings. 
  #
  # Rotate::        integer (Optional; inheritable) The number of degrees by
  #                 which the page should be rotated clockwise when
  #                 displayed or printed. The value must be a multiple of
  #                 90. Default value: 0. 
  # Group::         dictionary (Optional; PDF 1.4) A group attributes
  #                 dictionary specifying the attributes of the page’s page
  #                 group for use in the transparent imaging model (see
  #                 Sections 7.3.6, “Page Group,” and 7.5.5, “Transparency
  #                 Group XObjects”). 
  # Thumb::         stream (Optional) A stream object defining the page’s
  #                 thumbnail image (see Section 8.2.3, “Thumbnail Images”). 
  # B::             array (Optional; PDF 1.1; recommended if the page
  #                 contains article beads) An array of indirect references
  #                 to article beads appearing on the page (see Section
  #                 8.3.2, “Articles”; see also implementation note 37 in
  #                 Appendix H). The beads are listed in the array in
  #                 natural reading order. 
  # Dur::           number (Optional; PDF 1.1) The page’s display duration
  #                 (also called its advance timing): the maximum length of
  #                 time, in seconds, that the page is displayed during
  #                 presentations before the viewer application
  #                 automatically advances to the next page (see Section
  #                 8.3.3, “Presentations”). By default, the viewer does not
  #                 advance automatically. 
  # Trans::         dictionary (Optional; PDF 1.1) A transition dictionary
  #                 describing the transition effect to be used when
  #                 displaying the page during presentations (see Section
  #                 8.3.3, “Presentations”). 
  # Annots::        array (Optional) An array of annotation dictionaries
  #                 representing annotations associated with the page (see
  #                 Section 8.4, “Annotations”). 
  # AA::            dictionary (Optional; PDF 1.2) An additional-actions
  #                 dictionary defining actions to be performed when the
  #                 page is opened or closed (see Section 8.5.2, “Trigger
  #                 Events”; see also implementation note 38 in Appendix H). 
  # Metadata::      stream (Optional; PDF 1.4) A metadata stream containing
  #                 metadata for the page (see Section 10.2.2, “Metadata
  #                 Streams”). 
  # PieceInfo::     dictionary (Optional; PDF 1.3) A page-piece dictionary
  #                 associated with the page (see Section 10.4, “Page-Piece
  #                 Dictionaries”). 
  # StructParents:: integer (Required if the page contains structural
  #                 content items; PDF 1.3) The integer key of the page’s
  #                 entry in the structural parent tree (see “Finding
  #                 Structure Elements from Content Items” on page 797). 
  # ID::            string (Optional; PDF 1.3; indirect reference preferred)
  #                 The digital identifier of the page’s parent Web Capture
  #                 content set (see Section 10.9.5, “Object Attributes
  #                 Related to Web Capture”). 
  # PZ::            number (Optional; PDF 1.3) The page’s preferred zoom
  #                 (magnification) factor: the factor by which it should be
  #                 scaled to achieve the natural display magnification (see
  #                 Section 10.9.5, “Object Attributes Related to Web
  #                 Capture”). 
  # SeparationInfo::  dictionary (Optional; PDF 1.3) A separation dictionary
  #                   containing information needed to generate color
  #                   separations for the page (see Section 10.10.3,
  #                   “Separation Dictionaries”). 
  # Tabs::          name (Optional; PDF 1.5) A name specifying the tab order
  #                 to be used for annotations on the page. The possible
  #                 values are R (row order), C (column order), and S
  #                 (structure order). See Section 8.4, “Annotations,” for
  #                 details.
  # TemplateInstantiated::  name (Required if this page was created from a
  #                         named page object; PDF 1.5) The name of the
  #                         originating page object (see Section 8.6.5,
  #                         “Named Pages”). 
  # PresSteps::     dictionary (Optional; PDF 1.5) A navigation node
  #                 dictionary representing the first node on the page (see
  #                 “Sub-page Navigation” on page 566).
  # UserUnit::      number (Optional; PDF 1.6) A positive number giving the
  #                 size of default user space units, in multiples of 1/72
  #                 inch. The range of supported values is
  #                 implementation-dependent; see implementation note 171 in
  #                 Appendix H. Default value: 1.0 (user unit is 1/72 inch).
  # VP::            dictionary (Optional; PDF 1.6) An array of viewport
  #                 dictionaries (see Table 8.105) specifying rectangular
  #                 regions of the page.
