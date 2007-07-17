#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: writer.rb,v 1.38.2.2 2005/09/07 17:01:14 austin Exp $
#++
require 'thread'
require 'open-uri'

require 'transaction/simple'
require 'color'

  # A class to provide the core functionality to create a PDF document
  # without any requirement for additional modules.
module PDF
  class Writer
      # The version of PDF::Writer.
    VERSION = '1.1.3'

      # Escape the text so that it's safe for insertion into the PDF
      # document.
    def self.escape(text)
      text.gsub(/\\/, '\\\\\\\\').
           gsub(/\(/, '\\(').
           gsub(/\)/, '\\)').
           gsub(/&lt;/, '<').
           gsub(/&gt;/, '>').
           gsub(/&amp;/, '&')
    end
  end
end

require 'pdf/math'
require 'pdf/writer/lang'
require 'pdf/writer/lang/en'

begin
  require 'zlib'
  PDF::Writer::Compression = true
rescue LoadError
  warn PDF::Writer::Lang[:no_zlib_no_compress]
  PDF::Writer::Compression = false
end

require 'pdf/writer/arc4'
require 'pdf/writer/fontmetrics'
require 'pdf/writer/object'
require 'pdf/writer/object/action'
require 'pdf/writer/object/annotation'
require 'pdf/writer/object/catalog'
require 'pdf/writer/object/contents'
require 'pdf/writer/object/destination'
require 'pdf/writer/object/encryption'
require 'pdf/writer/object/font'
require 'pdf/writer/object/fontdescriptor'
require 'pdf/writer/object/fontencoding'
require 'pdf/writer/object/image'
require 'pdf/writer/object/info'
require 'pdf/writer/object/outlines'
require 'pdf/writer/object/outline'
require 'pdf/writer/object/page'
require 'pdf/writer/object/pages'
require 'pdf/writer/object/procset'
require 'pdf/writer/object/viewerpreferences'

require 'pdf/writer/ohash'
require 'pdf/writer/strokestyle'
require 'pdf/writer/graphics'
require 'pdf/writer/graphics/imageinfo'
require 'pdf/writer/state'

class PDF::Writer
    # The system font path. The sytem font path will be determined
    # differently for each operating system.
    #
    # Win32:: Uses ENV['SystemRoot']/Fonts as the system font path. There is
    #         an extension that will handle this better, but until and
    #         unless it is distributed with the standard Ruby Windows
    #         installer, PDF::Writer will not depend upon it.
    # OS X::  The fonts are found in /System/Library/Fonts.
    # Linux:: The font path list will be found (usually) in
    #         /etc/fonts/fonts.conf or /usr/etc/fonts/fonts.conf. This XML
    #         file will be parsed (using REXML) to provide the value for
    #         FONT_PATH.
  FONT_PATH = []

  class << self
    require 'rexml/document'
      # Parse the fonts.conf XML file.
    def parse_fonts_conf(filename)
      doc = REXML::Document.new(File.open(filename, "rb")).root rescue nil

      if doc
        path = REXML::XPath.match(doc, '//dir').map do |el|
          el.text.gsub($/, '')
        end
        doc = nil
      else
        path = []
      end
      path
    end
    private :parse_fonts_conf
  end

  case RUBY_PLATFORM
  when /mswin32/o
      # Windows font path. This is not the most reliable method.
    FONT_PATH << File.join(ENV['SystemRoot'], 'Fonts')
  when /darwin/o
      # Macintosh font path.
    FONT_PATH << '/System/Library/Fonts'
  else
    FONT_PATH.push(*parse_fonts_conf('/etc/fonts/fonts.conf'))
    FONT_PATH.push(*parse_fonts_conf('//usr/etc/fonts/fonts.conf'))
  end

  FONT_PATH.uniq!

  include PDF::Writer::Graphics

    # Contains all of the PDF objects, ready for final assembly. This is of
    # no interest to external consumers.
  attr_reader :objects #:nodoc:

    # The ARC4 encryption object. This is of no interest to external
    # consumers.
  attr_reader :arc4 #:nodoc:
    # The string that will be used to encrypt this PDF document.
  attr_accessor :encryption_key

    # The number of PDF objects in the document
  def size
    @objects.size
  end

    # Generate an ID for a new PDF object.
  def generate_id
    @mutex.synchronize { @current_id += 1 }
  end
  private :generate_id

    # Generate a new font ID.
  def generate_font_id
    @mutex.synchronize { @current_font_id += 1 }
  end
  private :generate_font_id

  class << self
      # Create the document with prepress options. Uses the same options as
      # PDF::Writer.new (<tt>:paper</tt>, <tt>:orientation</tt>, and
      # <tt>:version</tt>). It also supports the following options:
      #
      # <tt>:left_margin</tt>::   The left margin.
      # <tt>:right_margin</tt>::  The right margin.
      # <tt>:top_margin</tt>::    The top margin.
      # <tt>:bottom_margin</tt>:: The bottom margin.
      # <tt>:bleed_size</tt>::    The size of the bleed area in points.
      #                           Default 12.
      # <tt>:mark_length</tt>::   The length of the prepress marks in
      #                           points. Default 18.
      #
      # The prepress marks are added to the loose objects and will appear on
      # all pages.
    def prepress(options = { })
      pdf = self.new(options)

      bleed_size  = options[:bleed_size] || 12
      mark_length = options[:mark_length] || 18

      pdf.left_margin   = options[:left_margin] if options[:left_margin]
      pdf.right_margin  = options[:right_margin] if options[:right_margin]
      pdf.top_margin    = options[:top_margin] if options[:top_margin]
      pdf.bottom_margin = options[:bottom_margin] if options[:bottom_margin]

      # This is in an "odd" order because the y-coordinate system in PDF
      # is from bottom to top.
      tx0 = pdf.pages.media_box[0] + pdf.left_margin
      ty0 = pdf.pages.media_box[3] - pdf.top_margin
      tx1 = pdf.pages.media_box[2] - pdf.right_margin
      ty1 = pdf.pages.media_box[1] + pdf.bottom_margin

      bx0 = tx0 - bleed_size
      by0 = ty0 - bleed_size
      bx1 = tx1 + bleed_size
      by1 = ty1 + bleed_size

      pdf.pages.trim_box  = [ tx0, ty0, tx1, ty1 ]
      pdf.pages.bleed_box = [ bx0, by0, bx1, by1 ]

      all = pdf.open_object
      pdf.save_state
      kk = Color::CMYK.new(0, 0, 0, 100)
      pdf.stroke_color! kk
      pdf.fill_color! kk
      pdf.stroke_style! StrokeStyle.new(0.3)

      pdf.prepress_clip_mark(tx1, ty0,   0, mark_length, bleed_size)  # Upper Right
      pdf.prepress_clip_mark(tx0, ty0,  90, mark_length, bleed_size)  # Upper Left
      pdf.prepress_clip_mark(tx0, ty1, 180, mark_length, bleed_size)  # Lower Left
      pdf.prepress_clip_mark(tx1, ty1, -90, mark_length, bleed_size)  # Lower Right

      mid_x = pdf.pages.media_box[2] / 2.0
      mid_y = pdf.pages.media_box[3] / 2.0

      pdf.prepress_center_mark(mid_x, ty0,   0, mark_length, bleed_size) # Centre Top
      pdf.prepress_center_mark(tx0, mid_y,  90, mark_length, bleed_size) # Centre Left
      pdf.prepress_center_mark(mid_x, ty1, 180, mark_length, bleed_size) # Centre Bottom
      pdf.prepress_center_mark(tx1, mid_y, -90, mark_length, bleed_size) # Centre Right

      pdf.restore_state
      pdf.close_object
      pdf.add_object(all, :all)

      yield pdf if block_given?

      pdf
    end

      # Convert a measurement in centimetres to points, which are the
      # default PDF userspace units.
    def cm2pts(x)
      (x / 2.54) * 72
    end

      # Convert a measurement in millimetres to points, which are the
      # default PDF userspace units.
    def mm2pts(x)
      (x / 25.4) * 72
    end

      # Convert a measurement in inches to points, which are the default PDF
      # userspace units.
    def in2pts(x)
      x * 72
    end
  end

    # Convert a measurement in centimetres to points, which are the default
    # PDF userspace units.
  def cm2pts(x)
    PDF::Writer.cm2pts(x)
  end

    # Convert a measurement in millimetres to points, which are the default
    # PDF userspace units.
  def mm2pts(x)
    PDF::Writer.mm2pts(x)
  end

    # Convert a measurement in inches to points, which are the default PDF
    # userspace units.
  def in2pts(x)
    PDF::Writer.in2pts(x)
  end

    # Standard page size names. One of these may be provided to
    # PDF::Writer.new as the <tt>:paper</tt> parameter.
    #
    # Page sizes supported are:
    #
    # * 4A0, 2A0
    # * A0, A1 A2, A3, A4, A5, A6, A7, A8, A9, A10
    # * B0, B1, B2, B3, B4, B5, B6, B7, B8, B9, B10
    # * C0, C1, C2, C3, C4, C5, C6, C7, C8, C9, C10
    # * RA0, RA1, RA2, RA3, RA4
    # * SRA0, SRA1, SRA2, SRA3, SRA4
    # * LETTER
    # * LEGAL
    # * FOLIO
    # * EXECUTIVE
  PAGE_SIZES = { # :value {...}:
    "4A0"   => [0, 0, 4767.87, 6740.79], "2A0"    => [0, 0, 3370.39, 4767.87],
    "A0"    => [0, 0, 2383.94, 3370.39], "A1"     => [0, 0, 1683.78, 2383.94],
    "A2"    => [0, 0, 1190.55, 1683.78], "A3"     => [0, 0,  841.89, 1190.55],
    "A4"    => [0, 0,  595.28,  841.89], "A5"     => [0, 0,  419.53,  595.28],
    "A6"    => [0, 0,  297.64,  419.53], "A7"     => [0, 0,  209.76,  297.64],
    "A8"    => [0, 0,  147.40,  209.76], "A9"     => [0, 0,  104.88,  147.40],
    "A10"   => [0, 0,   73.70,  104.88], "B0"     => [0, 0, 2834.65, 4008.19],
    "B1"    => [0, 0, 2004.09, 2834.65], "B2"     => [0, 0, 1417.32, 2004.09],
    "B3"    => [0, 0, 1000.63, 1417.32], "B4"     => [0, 0,  708.66, 1000.63],
    "B5"    => [0, 0,  498.90,  708.66], "B6"     => [0, 0,  354.33,  498.90],
    "B7"    => [0, 0,  249.45,  354.33], "B8"     => [0, 0,  175.75,  249.45],
    "B9"    => [0, 0,  124.72,  175.75], "B10"    => [0, 0,   87.87,  124.72],
    "C0"    => [0, 0, 2599.37, 3676.54], "C1"     => [0, 0, 1836.85, 2599.37],
    "C2"    => [0, 0, 1298.27, 1836.85], "C3"     => [0, 0,  918.43, 1298.27],
    "C4"    => [0, 0,  649.13,  918.43], "C5"     => [0, 0,  459.21,  649.13],
    "C6"    => [0, 0,  323.15,  459.21], "C7"     => [0, 0,  229.61,  323.15],
    "C8"    => [0, 0,  161.57,  229.61], "C9"     => [0, 0,  113.39,  161.57],
    "C10"   => [0, 0,   79.37,  113.39], "RA0"    => [0, 0, 2437.80, 3458.27],
    "RA1"   => [0, 0, 1729.13, 2437.80], "RA2"    => [0, 0, 1218.90, 1729.13],
    "RA3"   => [0, 0,  864.57, 1218.90], "RA4"    => [0, 0,  609.45,  864.57],
    "SRA0"  => [0, 0, 2551.18, 3628.35], "SRA1"   => [0, 0, 1814.17, 2551.18],
    "SRA2"  => [0, 0, 1275.59, 1814.17], "SRA3"   => [0, 0,  907.09, 1275.59],
    "SRA4"  => [0, 0,  637.80,  907.09], "LETTER" => [0, 0,  612.00,  792.00],
    "LEGAL" => [0, 0,  612.00, 1008.00], "FOLIO"  => [0, 0,  612.00,  936.00],
    "EXECUTIVE" => [0, 0,  521.86,  756.00]
  }

    # Creates a new PDF document as a writing canvas. It accepts three named
    # parameters:
    #
    # <tt>:paper</tt>::       Specifies the size of the default page in
    #                         PDF::Writer. This may be a four-element array
    #                         of coordinates specifying the lower-left
    #                         <tt>(xll, yll)</tt> and upper-right <tt>(xur,
    #                         yur)</tt> corners, a two-element array of
    #                         width and height in centimetres, or a page
    #                         name as defined in PAGE_SIZES.
    # <tt>:orientation</tt>:: The orientation of the page, either long
    #                         (:portrait) or wide (:landscape). This may be
    #                         used to swap the width and the height of the
    #                         page.
    # <tt>:version</tt>::     The feature set available to the document is
    #                         limited by the PDF version. Setting this
    #                         version restricts the feature set available to
    #                         PDF::Writer. PDF::Writer currently supports
    #                         PDF version 1.3 features and does not yet
    #                         support advanced features from PDF 1.4, 1.5,
    #                         or 1.6.
  def initialize(options = {})
    paper       = options[:paper] || "LETTER"
    orientation = options[:orientation] || :portrait
    version     = options[:version] || PDF_VERSION_13

    @mutex = Mutex.new
    @current_id = @current_font_id = 0

      # Start the document
    @objects              = []
    @callbacks            = []
    @font_families        = {}
    @fonts                = {}
    @stack                = []
    @state_stack          = StateStack.new
    @loose_objects        = []
    @current_text_state   = ""
    @options              = {}
    @destinations         = {}
    @add_loose_objects    = {}
    @images               = []
    @word_space_adjust    = nil
    @current_stroke_style = PDF::Writer::StrokeStyle.new(1)
    @page_numbering       = nil
    @arc4                 = nil
    @encryption           = nil
    @file_identifier      = nil

    @columns              = {}
    @columns_on           = false
    @insert_mode          = nil

    @catalog  = PDF::Writer::Object::Catalog.new(self)
    @outlines = PDF::Writer::Object::Outlines.new(self)
    @pages    = PDF::Writer::Object::Pages.new(self)

    @current_node	= @pages
    @procset  = PDF::Writer::Object::Procset.new(self)
    @info     = PDF::Writer::Object::Info.new(self)
    @page     = PDF::Writer::Object::Page.new(self)
    @current_text_render_style  = 0
    @first_page     = @page

    @version        = version

      # Initialize the default font families.
    init_font_families

      # Items formerly in EZWriter
    @font_size = 10
    @pageset = []

    if paper.kind_of?(Array)
      if paper.size == 4
        size = paper # Coordinate Array
      else
        size = [0, 0, PDF::Writer.cm2pts(paper[0]), PDF::Writer.cm2pts(paper[1])]
          # Paper size in centimeters has been passed
      end
    else
      size = PAGE_SIZES[paper.upcase].dup
    end
    size[3], size[2] = size[2], size[3] if orientation == :landscape

    @pages.media_box  = size

    @page_width       = size[2] - size[0]
    @page_height      = size[3] - size[1]
    @y = @page_height

      # Also set the margins to some reasonable defaults -- 1.27 cm, 36pt,
      # or 0.5 inches.
    margins_pt(36)

      # Set the current writing position to the top of the first page
    @y = absolute_top_margin
      # Get the ID of the page that was created during the instantiation
      # process.
    @pageset[1] = @pages.first_page

    fill_color!   Color::RGB::Black
    stroke_color! Color::RGB::Black

    yield self if block_given?
  end

  PDF_VERSION_13  = '1.3'
  PDF_VERSION_14  = '1.4'
  PDF_VERSION_15  = '1.5'
  PDF_VERSION_16  = '1.6'

    # The version of PDF to which this document conforms. Should be one of
    # PDF_VERSION_13, PDF_VERSION_14, PDF_VERSION_15, or PDF_VERSION_16.
  attr_reader :version
    # The document catalog object (PDF::Writer::Object::Catalog). The
    # options in the catalog should be set with PDF::Writer#open_here,
    # PDF::Writer#viewer_preferences, and PDF::Writer#page_mode.
    #
    # This is of little interest to external clients.
  attr_accessor :catalog #:nodoc:
    # The PDF::Writer::Object::Pages object. This is of little interest to
    # external clients.
  attr_accessor :pages #:nodoc:

    # The PDF::Writer::Object::Procset object. This is of little interest to
    # external clients.
  attr_accessor :procset #:nodoc:
    # Sets the document to compressed (+true+) or uncompressed (+false+).
    # Defaults to uncompressed. This can ONLY be set once and should be set
    # as early as possible in the document creation process.
  attr_accessor :compressed
  def compressed=(cc) #:nodoc:
    @compressed = cc if @compressed.nil?
  end
    # Returns +true+ if the document is compressed.
  def compressed?
    @compressed == true
  end
    # The set of known labelled destinations. All destinations are of class
    # PDF::Writer::Object::Destination. This is of little interest to
    # external clients.
  attr_reader :destinations #:nodoc:
    # The PDF::Writer::Object::Info info object. This is used to provide
    # certain metadata.
  attr_reader :info
    # The current page for writing. This is of little interest to external
    # clients.
  attr_accessor :current_page #:nodoc:
    # Returns the current contents object to which raw PDF instructions may
    # be written.
  attr_reader :current_contents
    # The PDF::Writer::Object::Outlines object. This is currently used very
    # little. This is of little interest to external clients.
  attr_reader :outlines #:nodoc:

    # The complete set of page objects. This is of little interest to
    # external consumers.
  attr_reader :pageset #:nodoc:

  attr_accessor :left_margin
  attr_accessor :right_margin
  attr_accessor :top_margin
  attr_accessor :bottom_margin
  attr_reader :page_width
  attr_reader :page_height

    # The absolute x position of the left margin.
  attr_reader :absolute_left_margin
  def absolute_left_margin #:nodoc:
    @left_margin
  end
    # The absolute x position of the right margin.
  attr_reader :absolute_right_margin
  def absolute_right_margin #:nodoc:
    @page_width - @right_margin
  end
    # Returns the absolute y position of the top margin.
  attr_reader :absolute_top_margin
  def absolute_top_margin #:nodoc:
    @page_height - @top_margin
  end
    # Returns the absolute y position of the bottom margin.
  attr_reader :absolute_bottom_margin
  def absolute_bottom_margin #:nodoc:
    @bottom_margin
  end

    # The height of the margin area.
  attr_reader :margin_height
  def margin_height #:nodoc:
    absolute_top_margin - absolute_bottom_margin
  end
    # The width of the margin area.
  attr_reader :margin_width
  def margin_width #:nodoc:
    absolute_right_margin - absolute_left_margin
  end
    # The absolute x middle position.
  attr_reader :absolute_x_middle
  def absolute_x_middle #:nodoc:
    @page_width / 2.0
  end
    # The absolute y middle position.
  attr_reader :absolute_y_middle
  def absolute_y_middle #:nodoc:
    @page_height / 2.0
  end
    # The middle of the writing area between the left and right margins.
  attr_reader :margin_x_middle
  def margin_x_middle #:nodoc:
    (absolute_right_margin + absolute_left_margin) / 2.0
  end
    # The middle of the writing area between the top and bottom margins.
  attr_reader :margin_y_middle
  def margin_y_middle #:nodoc:
    (absolute_top_margin + absolute_bottom_margin) / 2.0
  end

    # The vertical position of the writing point. The vertical position is
    # constrained between the top and bottom margins. Any attempt to set it
    # outside of those margins will cause the y pointer to be placed
    # absolutely at the margins.
  attr_accessor :y
  def y=(yy) #:nodoc:
    @y = yy
    @y = absolute_top_margin if @y > absolute_top_margin
    @y = @bottom_margin if @y < @bottom_margin
  end

    # The vertical position of the writing point. If the vertical position
    # is outside of the bottom margin, a new page will be created.
  attr_accessor :pointer
  def pointer=(y) #:nodoc:
    @y = y
    start_new_page if @y < @bottom_margin
  end

    # Used to change the vertical position of the writing point. The pointer
    # is moved *down* the page by +dy+ (that is, #y is reduced by +dy+), so
    # if the pointer is to be moved up, a negative number must be used.
    # Moving up the page will not move to the previous page because of
    # limitations in the way that PDF::Writer works. The writing point will
    # be limited to the top margin position.
    #
    # If +make_space+ is true and a new page is forced, then the pointer
    # will be moved down on the new page. This will allow space to be
    # reserved for graphics.
  def move_pointer(dy, make_space = false)
    @y -= dy
    if @y < @bottom_margin
      start_new_page
      @y -= dy if make_space
    elsif @y > absolute_top_margin
      @y = absolute_top_margin
    end
  end

    # Define the margins in millimetres.
  def margins_mm(top, left = top, bottom = top, right = left)
    margins_pt(mm2pts(top), mm2pts(left), mm2pts(bottom), mm2pts(right))
  end

    # Define the margins in centimetres.
  def margins_cm(top, left = top, bottom = top, right = left)
    margins_pt(cm2pts(top), cm2pts(left), cm2pts(bottom), cm2pts(right))
  end

    # Define the margins in inches.
  def margins_in(top, left = top, bottom = top, right = left)
    margins_pt(in2pts(top), in2pts(left), in2pts(bottom), in2pts(right))
  end

    # Define the margins in points. This will move the #y pointer 
    #
    #                                   # T  L  B  R
    #   pdf.margins_pt(36)              # 36 36 36 36
    #   pdf.margins_pt(36, 54)          # 36 54 36 54
    #   pdf.margins_pt(36, 54, 72)      # 36 54 72 54
    #   pdf.margins_pt(36, 54, 72, 90)  # 36 54 72 90
  def margins_pt(top, left = top, bottom = top, right = left)
      # Set the margins to new values
    @top_margin    = top
    @bottom_margin = bottom
    @left_margin   = left
    @right_margin  = right
      # Check to see if this means that the current writing position is
      # outside the writable area
    if @y > (@page_height - top)
        # Move y down
      @y = @page_height - top
    end

    start_new_page if @y < bottom # Make a new page
  end

    # Allows the user to find out what the ID is of the first page that was
    # created during startup - useful if they wish to add something to it
    # later.
  attr_reader :first_page

    # Add a new translation table for a font family. A font family will be
    # used to associate a single name and font styles with multiple fonts.
    # A style will be identified with a single-character style identifier or
    # a series of style identifiers. The only styles currently recognised
    # are:
    #
    # +b+::   Bold (or heavy) fonts. Examples: Helvetica-Bold, Courier-Bold,
    #         Times-Bold.
    # +i+::   Italic (or oblique) fonts. Examples: Helvetica-Oblique,
    #         Courier-Oblique, Times-Italic.
    # +bi+::  Bold italic fonts. Examples Helvetica-BoldOblique,
    #         Courier-BoldOblique, Times-BoldItalic.
    # +ib+::  Italic bold fonts. Generally defined the same as +bi+ font
    #         styles. Examples: Helvetica-BoldOblique, Courier-BoldOblique,
    #         Times-BoldItalic.
    #
    # Each font family key is the base name for the font.
  attr_reader :font_families

    # Initialize the font families for the default fonts.
  def init_font_families
      # Set the known family groups. These font families will be used to
      # enable bold and italic markers to be included within text
      # streams. HTML forms will be used... <b></b> <i></i>
    @font_families["Helvetica"] =
    {
      "b"   => 'Helvetica-Bold',
      "i"   => 'Helvetica-Oblique',
      "bi"  => 'Helvetica-BoldOblique',
      "ib"  => 'Helvetica-BoldOblique'
    }
    @font_families['Courier'] =
    {
      "b"   => 'Courier-Bold',
      "i"   => 'Courier-Oblique',
      "bi"  => 'Courier-BoldOblique',
      "ib"  => 'Courier-BoldOblique'
    }
    @font_families['Times-Roman'] =
    {
      "b"   => 'Times-Bold',
      "i"   => 'Times-Italic',
      "bi"  => 'Times-BoldItalic',
      "ib"  => 'Times-BoldItalic'
    }
  end
  private :init_font_families

    # Sets the trim box area.
  def trim_box(x0, y0, x1, y1)
    @pages.trim_box = [ x0, y0, x1, y1 ]
  end

    # Sets the bleed box area.
  def bleed_box(x0, y0, x1, y1)
    @pages.bleed_box = [ x0, y0, x1, y1 ]
  end

    # set the viewer preferences of the document, it is up to the browser to
    # obey these.
  def viewer_preferences(label, value = 0)
    @catalog.viewer_preferences ||= PDF::Writer::Object::ViewerPreferences.new(self)

      # This will only work if the label is one of the valid ones.
    if label.kind_of?(Hash)
      label.each { |kk, vv| @catalog.viewer_preferences.__send__("#{kk.downcase}=".intern, vv) }
    else
      @catalog.viewer_preferences.__send__("#{label.downcase}=".intern, value)
    end
  end

    # Add a link in the document to an external URL.
  def add_link(uri, x0, y0, x1, y1)
    PDF::Writer::Object::Annotation.new(self, :link, [x0, y0, x1, y1], uri)
  end

    # Add a link in the document to an internal destination (ie. within the
    # document)
  def add_internal_link(label, x0, y0, x1, y1)
    PDF::Writer::Object::Annotation.new(self, :ilink, [x0, y0, x1, y1], label)
  end

    # Add an outline item (Bookmark).
  def add_outline_item(label, title = label)
    PDF::Writer::Object::Outline.new(self, label, title)
  end

    # Standard encryption/DRM options.
  ENCRYPT_OPTIONS = { #:nodoc:
    :print  => 4,
    :modify => 8,
    :copy   => 16,
    :add    => 32
  }

  # Encrypts the document. This will set the user and owner passwords that
  # will be used to access the document and set the permissions the user
  # has with the document. The passwords are limited to 32 characters.
  #
  # The permissions provided are an array of symbols, allowing identified
  # users to perform particular actions:
  # <tt>:print</tt>::   Print.
  # <tt>:modify</tt>::  Modify text or objects.
  # <tt>:copy</tt>::    Copy text or objects.
  # <tt>:add</tt>::     Add text or objects.
  def encrypt(user_pass = nil, owner_pass = nil, permissions = [])
    perms = ["11000000"].pack("B8")

    permissions.each do |perm|
      perms += ENCRYPT_OPTIONS[perm] if ENCRYPT_OPTIONS[perm]
    end

    @arc4 ||= PDF::ARC4.new
    owner_pass ||= user_pass

    options = {
      :owner_pass   => owner_pass,
      :user_pass    => user_pass,
      :permissions  => perms,
    }
    @encryption = PDF::Writer::Object::Encryption.new(self, options)
  end

  def encrypted?
    not @encryption.nil?
  end

    # should be used for internal checks, not implemented as yet
  def check_all_here
  end

    # Return the PDF stream as a string.
  def render(debug = false)
    add_page_numbers
    @compression = false if $DEBUG or debug
    @arc4.init(@encryption_key) unless @arc4.nil?

    check_all_here

    xref = []

    content = "%PDF-#{@version}\n%‚„œ”\n"
    pos = content.size

    objects.each do |oo|
      cont = oo.to_s
      content << cont
      xref << pos
      pos += cont.size
    end

#   pos += 1 # Newline character before XREF

    content << "\nxref\n0 #{xref.size + 1}\n0000000000 65535 f \n"
    xref.each { |xx| content << "#{'%010d' % [xx]} 00000 n \n" }
    content << "\ntrailer\n"
    content << "  << /Size #{xref.size + 1}\n"
    content << "     /Root 1 0 R\n /Info #{@info.oid} 0 R\n"
      # If encryption has been applied to this document, then add the marker
      # for this dictionary
    if @arc4 and @encryption
      content << "/Encrypt #{@encryption.oid} 0 R\n"
    end

    if @file_identifier
      content << "/ID[<#{@file_identifier}><#{@file_identifier}>]\n"
    end
    content << "  >>\nstartxref\n#{pos}\n%%EOF\n"
    content
  end
  alias :to_s :render

    # Loads the font metrics. This is now thread-safe.
  def load_font_metrics(font)
    metrics = PDF::Writer::FontMetrics.open(font)
    @mutex.synchronize do
      @fonts[font] = metrics
      @fonts[font].font_num = @fonts.size
    end
    metrics
  end
  private :load_font_metrics

  def find_font(fontname)
    name = File.basename(fontname, ".afm")
    @objects.detect do |oo|
      oo.kind_of?(PDF::Writer::Object::Font) and /#{oo.basefont}$/ =~ name
    end
  end
  private :find_font

  def font_file(fontfile)
    path = "#{fontfile}.pfb"
    return path if File.exists?(path)
    path = "#{fontfile}.ttf"
    return path if File.exists?(path)
    nil
  end
  private :font_file

  def load_font(font, encoding = nil)
    metrics = load_font_metrics(font)

    name  = File.basename(font).gsub(/\.afm$/o, "")

    encoding_diff = nil
    case encoding
    when Hash
      encoding_name = encoding[:encoding]
      encoding_diff = encoding[:differences]
      encoding      = PDF::Writer::Object::FontEncoding.new(self, encoding_name, encoding_diff)
    when NilClass
      encoding_name = encoding = 'WinAnsiEncoding'
    else
      encoding_name = encoding
    end

    wfo = PDF::Writer::Object::Font.new(self, name, encoding)

      # We have an Adobe Font Metrics (.afm) file. We need to find the
      # associated Type1 (.pfb) or TrueType (.ttf) files (we do not yet
      # support OpenType fonts); we need to load it into a
      # PDF::Writer::Object and put the references into the metrics object.
    base = metrics.path.sub(/\.afm$/o, "")
    fontfile = font_file(base)
    unless fontfile
      base = File.basename(base)
      FONT_PATH.each do |path|
        fontfile = font_file(File.join(path, base))
        break if fontfile
      end
    end

    if font =~ /afm/o and fontfile
        # Find the array of font widths, and put that into an object.
      first_char  = -1
      last_char   = 0

      widths = {}
      metrics.c.each_value do |details|
        num = details["C"]

        if num >= 0
          # warn "Multiple definitions of #{num}" if widths.has_key?(num)
          widths[num] = details['WX']
          first_char = num if num < first_char or first_char < 0
          last_char = num if num > last_char
        end
      end

      # Adjust the widths for the differences array.
      if encoding_diff
        encoding_diff.each do |cnum, cname|
          (cnum - last_char).times { widths << 0 } if cnum > last_char
          last_char = cnum
          widths[cnum - firstchar] = fonts.c[cname]['WX'] if metrics.c[cname]
        end
      end

      widthid = PDF::Writer::Object::Contents.new(self, :raw)
      widthid << "["
      (first_char .. last_char).each do |ii|
        if widths.has_key?(ii)
          widthid << " #{widths[ii].to_i}"
        else
          widthid << " 0"
        end
      end
      widthid << "]"

        # Load the pfb file, and put that into an object too. Note that PDF
        # supports only binary format Type1 font files and TrueType font
        # files. There is a simple utility to convert Type1 from pfa to pfb.
      data = File.open(fbfile, "rb") { |ff| ff.read }

        # Check to see if the font licence allows embedding.
      if fbtype =~ /\.ttf$/o
        offset  = 4
        tables  = data[offset, 2].unpack('n')[0]
        offset += 8

        found   = false
        tables.times do
          if data[offset, 4] == 'OS/2'
            found = true
            break
          end
          offset += 4 + 12
        end

        if found
          offset += 4
          newoff  = data[offset, 4].unpack('N')[0]
          offset  = newoff + 8
          licence = data[offset, 2].unpack('n')[0]

          rl  = ((licence & 0x02) != 0)
          pp  = ((licence & 0x04) != 0)
          ee  = ((licence & 0x08) != 0)

          if rl and pp and ee
            warn PDF::Writer::Lang[:ttf_licence_no_embedding] % name
          end
        end
      end

        # Create the font descriptor.
      fdsc = PDF::Writer::Object::FontDescriptor.new(self)
        # Raw contents causes problems with Acrobat Reader.
      pfbc = PDF::Writer::Object::Contents.new(self)

        # Determine flags (more than a little flakey, hopefully will not
        # matter much).
      flags = 0
      if encoding == "none"
        flags += 2 ** 2
      else
        flags += 2 ** 6 if metrics.italicangle.nonzero?
        flags += 2 ** 0 if metrics.isfixedpitch == "true"
        flags += 2 ** 5 # Assume a non-symbolic font
      end

        # 1: FixedPitch:  All glyphs have the same width (as opposed to
        #                 proportional or variable-pitch fonts, which have
        #                 different widths).
        # 2: Serif:       Glyphs have serifs, which are short strokes drawn
        #                 at an angle on the top and bottom of glyph stems.
        #                 (Sans serif fonts do not have serifs.)
        # 3: Symbolic     Font contains glyphs outside the Adobe standard
        #                 Latin character set. This flag and the Nonsymbolic
        #                 flag cannot both be set or both be clear (see
        #                 below).
        # 4: Script:      Glyphs resemble cursive handwriting.
        # 6: Nonsymbolic: Font uses the Adobe standard Latin character set
        #                 or a subset of it (see below).
        # 7: Italic:      Glyphs have dominant vertical strokes that are
        #                 slanted.
        # 17: AllCap:     Font contains no lowercase letters; typically used
        #                 for display purposes, such as for titles or
        #                 headlines.
        # 18: SmallCap:   Font contains both uppercase and lowercase
        #                 letters. The uppercase letters are similar to
        #                 those in the regular version of the same typeface
        #                 family. The glyphs for the lowercase letters have
        #                 the same shapes as the corresponding uppercase
        #                 letters, but they are sized and their proportions
        #                 adjusted so that they have the same size and
        #                 stroke weight as lowercase glyphs in the same
        #                 typeface family.
        # 19: ForceBold:  See below.

      list = {
        'Ascent'      => 'Ascender',
        'CapHeight'   => 'CapHeight',
        'Descent'     => 'Descender',
        'FontBBox'    => 'FontBBox',
        'ItalicAngle' => 'ItalicAngle'
      }
      fdopt = {
        'Flags'     => flags,
        'FontName'  => metrics.fontname,
        'StemV'     => 100 # Don't know what the value for this should be!
      }

      list.each do |kk, vv|
        zz = metrics.__send__(vv.downcase.intern)
        fdopt[kk] = zz if zz
      end

        # Determine the cruicial lengths within this file
      if fbtype =~ /\.pfb$/o
        fdopt['FontFile'] = pfbc.oid
        i1 = data.index('eexec') + 6
        i2 = data.index('00000000')  - i1
        i3 = data.size - i2 - i1
        pfbc.add('Length1' => i1, 'Length2' => i2, 'Length3' => i3)
      elsif fbtype =~ /\.ttf$/o
        fdopt['FontFile2'] = pfbc.oid
        pfbc.add('Length1' => data.size)
      end

      fdsc.options = fdopt
        # Embed the font program
      pfbc << data

      # Tell the font object about all this new stuff
      tmp = {
        'BaseFont'        => metrics.fontname,
        'Widths'          => widthid.oid,
        'FirstChar'       => first_char,
        'LastChar'        => last_char,
        'FontDescriptor'  => fdsc.oid
      }
      tmp['SubType'] = 'TrueType' if fbtype == "ttf"

      tmp.each { |kk, vv| wfo.__send__("#{kk.downcase}=".intern, vv) }
    end

      # Also set the differences here. Note that this means that these will
      # take effect only the first time that a font is selected, else they
      # are ignored.
    metrics.differences = encoding_diff unless encoding_diff.nil?
    metrics.encoding = encoding_name
    metrics
  end
  private :load_font

    # If the named +font+ is not loaded, then load it and make the required
    # PDF objects to represent the font. If the font is already loaded, then
    # make it the current font.
    #
    # The parameter +encoding+ applies only when the font is first being
    # loaded; it may not be applied later. It may either be an encoding name
    # or a hash. The Hash must contain two keys:
    #
    # <tt>:encoding</tt>::    The name of the encoding. Either *none*,
    #                         *WinAnsiEncoding*, *MacRomanEncoding*, or
    #                         *MacExpertEncoding*. For symbolic fonts, an
    #                         encoding of *none* is recommended with a
    #                         differences Hash.
    # <tt>:differences</tt>:: This Hash value is a mapping between character
    #                         byte values (0 .. 255) and character names
    #                         from the AFM file for the font.
    #
    # The standard PDF encodings are detailed fully in the PDF Reference
    # version 1.6, Appendix D.
    #
    # Note that WinAnsiEncoding is not the same as Windows code page 1252
    # (roughly equivalent to latin-1), Most characters map, but not all. The
    # encoding value currently defaults to WinAnsiEncoding.
    #
    # If the font's "natural" encoding is desired, then it is necessary to
    # specify the +encoding+ parameter as <tt>{ :encoding => nil }</tt>.
  def select_font(font, encoding = nil)
    load_font(font, encoding) unless @fonts[font]

    @current_base_font = font
    current_font!
    @current_base_font
  end

    # Selects the current font based on defined font families and the
    # current text state. As noted in #font_families, a "bi" font can be
    # defined differently than an "ib" font. It should not be possible to
    # have a "bb" text state, but if one were to show up, an entry for the
    # #font_families would have to be defined to select anything other than
    # the default font. This function is to be called whenever the current
    # text state is changed; it will update the current font to whatever the
    # appropriate font defined in the font family.
    #
    # When the user calls #select_font, both the current base font and the
    # current font will be reset; this function only changes the current
    # font, not the current base font.
    #
    # This will probably not be needed by end users.
  def current_font!
    select_font("Helvetica") unless @current_base_font

    font = File.basename(@current_base_font)
    if @font_families[font] and @font_families[font][@current_text_state]
        # Then we are in some state or another and this font has a family,
        # and the current setting exists within it select the font, then
        # return it.
      if File.dirname(@current_base_font) != '.'
        nf = File.join(File.dirname(@current_base_font), @font_families[font][@current_text_state])
      else
        nf = @font_families[font][@current_text_state]
      end

      unless @fonts[nf]
        enc = {
          :encoding     => @fonts[font].encoding,
          :differences  => @fonts[font].differences
        }
        load_font(nf, enc)
      end
      @current_font = nf
    else
      @current_font = @current_base_font
    end
  end

  attr_reader :current_font
  attr_reader :current_base_font
  attr_accessor :font_size

    # add content to the currently active object
  def add_content(cc)
    @current_contents << cc
  end

    # Return the height in units of the current font in the given size. Uses
    # the current #font_size if size is not provided.
  def font_height(size = nil)
    size = @font_size if size.nil? or size <= 0

    select_font("Helvetica") if @fonts.empty?
    hh = @fonts[@current_font].fontbbox[3].to_f - @fonts[@current_font].fontbbox[1].to_f
    (size * hh / 1000.0)
  end

    # Return the font descender, this will normally return a negative
    # number. If you add this number to the baseline, you get the level of
    # the bottom of the font it is in the PDF user units. Uses the current
    # #font_size if size is not provided.
  def font_descender(size = nil)
    size = @font_size if size.nil? or size <= 0

    select_font("Helvetica") if @fonts.empty?
    hi = @fonts[@current_font].fontbbox[1].to_f
    (size * hi / 1000.0)
  end

    # Given a start position and information about how text is to be laid
    # out, calculate where on the page the text will end.
  def text_end_position(x, y, angle, size, wa, text)
    width = text_width(text, size)
    width += wa * (text.count(" "))
    rad = PDF::Math.deg2rad(angle)
    [Math.cos(rad) * width + x, ((-Math.sin(rad)) * width + y)]
  end
  private :text_end_position

    # Wrapper function for #text_tags
  def quick_text_tags(text, ii, font_change)
    ret = text_tags(text, ii, font_change)
    [ret[0], ret[1], ret[2]]
  end
  private :quick_text_tags

    # Matches tags.
  MATCH_TAG_REPLACE_RE    = %r{^r:(\w+)(?: (.*?))? */} #:nodoc:
  MATCH_TAG_DRAW_ONE_RE   = %r{^C:(\w+)(?: (.*?))? */} #:nodoc:
  MATCH_TAG_DRAW_PAIR_RE  = %r{^c:(\w+)(?: (.*))? *} #:nodoc:

    # Checks if +text+ contains a control tag at +pos+. Control tags are
    # XML-like tags that contain tag information.
    #
    # === Supported Tag Formats
    # <tt>&lt;b></tt>::               Adds +b+ to the end of the current
    #                                 text state. If this is the closing
    #                                 tag, <tt>&lt;/b></tt>, +b+ is removed
    #                                 from the end of the current text
    #                                 state.
    # <tt>&lt;i></tt>::               Adds +i+ to the end of the current
    #                                 text state. If this is the closing
    #                                 tag, <tt>&lt;/i</tt>, +i+ is removed
    #                                 from the end of the current text
    #                                 state.
    # <tt>&lt;r:TAG[ PARAMS]/></tt>:: Calls a stand-alone replace callback
    #                                 method of the form tag_TAG_replace.
    #                                 PARAMS must be separated from the TAG
    #                                 name by a single space. The PARAMS, if
    #                                 present, are passed to the replace
    #                                 callback unmodified, whose
    #                                 responsibility it is to interpret the
    #                                 parameters. The replace callback is
    #                                 expected to return text that will be
    #                                 used in the place of the tag.
    #                                 #text_tags is called again immediately
    #                                 so that if the replacement text has
    #                                 tags, they will be dealt with
    #                                 properly.
    # <tt>&lt;C:TAG[ PARAMS]/></tt>:: Calls a stand-alone drawing callback
    #                                 method. The method will be provided an
    #                                 information hash (see below for the
    #                                 data provided). It is expected to use
    #                                 this information to perform whatever
    #                                 drawing tasks are needed to perform
    #                                 its task.
    # <tt>&lt;c:TAG[ PARAMS]></tt>::  Calls a paired drawing callback
    #                                 method. The method will be provided an
    #                                 information hash (see below for the
    #                                 data provided). It is expected to use
    #                                 this information to perform whatever
    #                                 drawing tasks are needed to perform
    #                                 its task. It must have a corresponding
    #                                 &lt;/c:TAG> closing tag. Paired
    #                                 callback behaviours will be preserved
    #                                 over page breaks and line changes.
    #
    # Drawing callback tags will be provided an information hash that tells
    # the callback method where it must perform its drawing tasks.
    #
    # === Drawing Callback Parameters
    # <tt>:x</tt>::         The current X position of the text.
    # <tt>:y</tt>::         The current y position of the text.
    # <tt>:angle</tt>::     The current text drawing angle.
    # <tt>:params</tt>::    Any parameters that may be important to the
    #                       callback. This value is only guaranteed to have
    #                       meaning when a stand-alone callback is made or the
    #                       opening tag is processed.
    # <tt>:status</tt>::    :start, :end, :start_line, :end_line
    # <tt>:cbid</tt>::      The identifier of this callback. This may be
    #                       used as a key into a different variable where
    #                       state may be kept.
    # <tt>:callback</tt>::  The name of the callback function. Only set for
    #                       stand-alone or opening callback tags.
    # <tt>:height</tt>::    The font height.
    # <tt>:descender</tt>:: The font descender size.
    #
    # ==== <tt>:status</tt> Values and Meanings
    # <tt>:start</tt>::       The callback has been started. This applies
    #                         either when the callback is a stand-alone
    #                         callback (<tt>&lt;C:TAG/></tt>) or the opening
    #                         tag of a paired tag (<tt>&lt;c:TAG></tt>).
    # <tt>:end</tt>::         The callback has been manually terminated with
    #                         a closing tag (<tt>&lt;/c:TAG></tt>).
    # <tt>:start_line</tt>::  Called when a new line is to be drawn. This
    #                         allows the callback to perform any updates
    #                         necessary to permit paired callbacks to cross
    #                         line boundaries. This will usually involve
    #                         updating x, y positions.
    # <tt>:end_line</tt>::    Called when the end of a line is reached. This
    #                         permits the callback to perform any drawing
    #                         necessary to permit paired callbacks to cross
    #                         line boundaries.
    #
    # Drawing callback methods may return a hash of the <tt>:x</tt> and
    # <tt>:y</tt> position that the drawing pointer should take after the
    # callback is complete.
    #
    # === Known Callback Tags
    # <tt>&lt;c:alink URI></tt>::   makes an external link around text
    #                               between the opening and closing tags of
    #                               this callback. The URI may be any URL,
    #                               including http://, ftp://, and mailto:,
    #                               as long as there is a URL handler
    #                               registered. URI is of the form
    #                               uri="URI".
    # <tt>&lt;c:ilink DEST></tt>::  makes an internal link within the
    #                               document. The DEST must refer to a known
    #                               named destination within the document.
    #                               DEST is of the form dest="DEST".
    # <tt>&lt;c:uline></tt>::       underlines the specified text.
    # <tt>&lt;C:bullet></tt>::      Draws a solid bullet at the tag
    #                               position.
    # <tt>&lt;C:disc></tt>::        Draws a disc bullet at the tag position.
  def text_tags(text, pos, font_change, final = false, x = 0, y = 0, size = 0, angle = 0, word_space_adjust = 0)
    tag_size = 0

    tag_match = %r!^<(/)?([^>]+)>!.match(text[pos..-1])

    if tag_match
      closed, tag_name = tag_match.captures
      cts = @current_text_state # Alias for shorter lines.
      tag_size = tag_name.size + 2 + (closed ? 1 : 0)

      case tag_name
      when %r{^(?:b|strong)$}o
        if closed
          cts.slice!(-1, 1) if ?b == cts[-1]
        else
          cts << ?b
        end
      when %r{^(?:i|em)$}o
        if closed
          cts.slice!(-1, 1) if ?i == cts[-1]
        else
          cts << ?i
        end
      when %r{^r:}o
        _match = MATCH_TAG_REPLACE_RE.match(tag_name)
        if _match.nil?
          warn PDF::Writer::Lang[:callback_warning] % [ 'r:', tag_name ]
          tag_size = 0
        else
          func    = _match.captures[0]
          params  = parse_tag_params(_match.captures[1] || "")
          tag     = TAGS[:replace][func]

          if tag
            text[pos, tag_size] = tag[self, params]
            tag_size, text, font_change, x, y = text_tags(text, pos,
                                                          font_change,
                                                          final, x, y, size,
                                                          angle,
                                                          word_space_adjust)
          else
            warn PDF::Writer::Lang[:callback_warning] % [ 'r:', func ]
            tag_size = 0
          end
        end
      when %r{^C:}o
        _match = MATCH_TAG_DRAW_ONE_RE.match(tag_name)
        if _match.nil?
          warn PDF::Writer::Lang[:callback_warning] % [ 'C:', tag_name ]
          tag_size = 0
        else
          func    = _match.captures[0]
          params  = parse_tag_params(_match.captures[1] || "")
          tag     = TAGS[:single][func]

          if tag
            font_change = false

            if final
              # Only call the function if this is the "final" call. Assess
              # the text position. Calculate the text width to this point.
              x, y = text_end_position(x, y, angle, size, word_space_adjust,
                                       text[0, pos])
              info = {
                :x          => x,
                :y          => y,
                :angle      => angle,
                :params     => params,
                :status     => :start,
                :cbid       => @callbacks.size + 1,
                :callback   => func,
                :height     => font_height(size),
                :descender  => font_descender(size)
              }

              ret = tag[self, info]
              if ret.kind_of?(Hash)
                ret.each do |rk, rv|
                  x           = rv if rk == :x
                  y           = rv if rk == :y
                  font_change = rv if rk == :font_change
                end
              end
            end
          else
            warn PDF::Writer::Lang[:callback_Warning] % [ 'C:', func ]
            tag_size = 0
          end
        end
      when %r{^c:}o
        _match = MATCH_TAG_DRAW_PAIR_RE.match(tag_name)

        if _match.nil?
          warn PDF::Writer::Lang[:callback_warning] % [ 'c:', tag_name ]
          tag_size = 0
        else
          func    = _match.captures[0]
          params  = parse_tag_params(_match.captures[1] || "")
          tag     = TAGS[:pair][func]

          if tag
            font_change = false

            if final
                # Only call the function if this is the "final" call. Assess
                # the text position. Calculate the text width to this point.
              x, y = text_end_position(x, y, angle, size, word_space_adjust,
                                       text[0, pos])
              info = {
                :x          => x,
                :y          => y,
                :angle      => angle,
                :params     => params,
              }

              if closed
                info[:status] = :end
                info[:cbid]   = @callbacks.size

                ret = tag[self, info]

                if ret.kind_of?(Hash)
                  ret.each do |rk, rv|
                    x           = rv if rk == :x
                    y           = rv if rk == :y
                    font_change = rv if rk == :font_change
                  end
                end

                @callbacks.pop
              else
                info[:status]     = :start
                info[:cbid]       = @callbacks.size + 1
                info[:tag]        = tag
                info[:callback]   = func
                info[:height]     = font_height(size)
                info[:descender]  = font_descender(size)

                @callbacks << info

                ret = tag[self, info]

                if ret.kind_of?(Hash)
                  ret.each do |rk, rv|
                    x           = rv if rk == :x
                    y           = rv if rk == :y
                    font_change = rv if rk == :font_change
                  end
                end
              end
            end
          else
            warn PDF::Writer::Lang[:callback_warning] % [ 'c:', func ]
            tag_size = 0
          end
        end
      else
        tag_size = 0
      end
    end
    [ tag_size, text, font_change, x, y ]
  end
  private :text_tags

  TAG_PARAM_RE  = %r{(\w+)=(?:"([^"]+)"|'([^']+)'|(\w+))} #:nodoc:

  def parse_tag_params(params)
    params ||= ""
    ph = {}
    params.scan(TAG_PARAM_RE) do |param|
      ph[param[0]] = param[1] || param[2] || param[3]
    end
    ph
  end
  private :parse_tag_params

    # Add +text+ to the document at <tt>(x, y)</tt> location at +size+ and
    # +angle+. The +word_space_adjust+ parameter is an internal parameter
    # that should not be used.
    #
    # As of PDF::Writer 1.1, +size+ and +text+ have been reversed and +size+
    # is now optional, defaulting to the current #font_size if unset.
  def add_text(x, y, text, size = nil, angle = 0, word_space_adjust = 0)
    if text.kind_of?(Numeric) and size.kind_of?(String)
      text, size = size, text
      warn PDF::Writer::Lang[:add_text_parameters_reversed] % caller[0]
    end

    if size.nil? or size <= 0
      size = @font_size
    end

    select_font("Helvetica") if @fonts.empty?

    text = text.to_s

      # If there are any open callbacks, then they should be called, to show
      # the start of the line
    @callbacks.reverse_each do |ii|
      info = ii.dup
      info[:x]      = x
      info[:y]      = y
      info[:angle]  = angle
      info[:status] = :start_line

      info[:tag][self, info]
    end
    if angle == 0
      add_content("\nBT %.3f %.3f Td" % [x, y])
    else
      rad = PDF::Math.deg2rad(angle)
      tt = "\nBT %.3f %.3f %.3f %.3f %.3f %.3f Tm"
      tt = tt % [ Math.cos(rad), Math.sin(rad), -Math.sin(rad), Math.cos(rad), x, y ]
      add_content(tt)
    end

    if (word_space_adjust != 0) or not ((@word_space_adjust.nil?) and (@word_space_adjust != word_space_adjust))
      @word_space_adjust = word_space_adjust
      add_content(" %.3f Tw" % word_space_adjust)
    end

    pos = -1
    start = 0
    loop do
      pos += 1
      break if pos == text.size
      font_change = true
      tag_size, text, font_change = quick_text_tags(text, pos, font_change)

      if tag_size != 0
        if pos > start
          part = text[start, pos - start]
          tt = " /F#{find_font(@current_font).font_id}"
          tt << " %.1f Tf %d Tr" % [ size, @current_text_render_style ]
          tt << " (#{PDF::Writer.escape(part)}) Tj"
          add_content(tt)
        end

        if font_change
          current_font!
        else
          add_content(" ET")
          xp = x
          yp = y
          tag_size, text, font_change, xp, yp = text_tags(text, pos, font_change, true, xp, yp, size, angle, word_space_adjust)

            # Restart the text object
          if angle.zero?
            add_content("\nBT %.3f %.3f Td" % [xp, yp])
          else
            rad = PDF::Math.deg2rad(angle)
            tt = "\nBT %.3f %.3f %.3f %.3f %.3f %.3f Tm"
            tt = tt % [ Math.cos(rad), Math.sin(rad), -Math.sin(rad), Math.cos(rad), xp, yp ]
            add_content(tt)
          end

          if (word_space_adjust != 0) or (word_space_adjust != @word_space_adjust)
            @word_space_adjust = word_space_adjust
            add_content(" %.3f Tw" % [word_space_adjust])
          end
        end

        pos += tag_size - 1
        start = pos + 1
      end
    end

    if start < text.size
      part = text[start..-1]

      tt = " /F#{find_font(@current_font).font_id}"
      tt << " %.1f Tf %d Tr" % [ size, @current_text_render_style ]
      tt << " (#{PDF::Writer.escape(part)}) Tj"
      add_content(tt)
    end
    add_content(" ET")

      # XXX: Experimental fix.
    @callbacks.reverse_each do |ii|
      info = ii.dup
      info[:x]      = x
      info[:y]      = y
      info[:angle]  = angle
      info[:status] = :end_line
      info[:tag][self, info]
    end
  end

  def char_width(font, char)
    char = char[0] unless @fonts[font].c[char]

    if @fonts[font].differences and @fonts[font].c[char].nil?
      name = @fonts[font].differences[char] || 'M'
      width = @fonts[font].c[name]['WX'] if @fonts[font].c[name]['WX']
    elsif @fonts[font].c[char]
      width = @fonts[font].c[char]['WX']
    else
      width = @fonts[font].c['M']['WX']
    end
    width
  end
  private :char_width

    # Calculate how wide a given text string will be on a page, at a given
    # size. This may be called externally, but is alse used by #text_width.
    # If +size+ is not specified, PDF::Writer will use the current
    # #font_size.
    #
    # The argument list is reversed from earlier versions.
  def text_line_width(text, size = nil)
    if text.kind_of?(Numeric) and size.kind_of?(String)
      text, size = size, text
      warn PDF::Writer::Lang[:text_width_parameters_reversed] % caller[0]
    end

    if size.nil? or size <= 0
      size = @font_size
    end

      # This function should not change any of the settings, though it will
      # need to track any tag which change during calculation, so copy them
      # at the start and put them back at the end.
    t_CTS = @current_text_state.dup

    select_font("Helvetica") if @fonts.empty?
      # converts a number or a float to a string so it can get the width
    tt = text.to_s
      # hmm, this is where it all starts to get tricky - use the font
      # information to calculate the width of each character, add them up
      # and convert to user units
    width = 0
    font = @current_font

    pos = -1
    loop do
      pos += 1
      break if pos == tt.size
      font_change = true
      tag_size, text, font_change = quick_text_tags(text, pos, font_change)
      if tag_size != 0
        if font_change
          current_font!
          font = @current_font
        end
        pos += tag_size - 1
      else
        if "&lt;" == tt[pos, 4]
          width += char_width(font, '<')
          pos += 3
        elsif "&gt;" == tt[pos, 4]
          width += char_width(font, '>')
          pos += 3
        elsif "&amp;" == tt[pos, 5]
          width += char_width(font, '&')
          pos += 4
        else
          width += char_width(font, tt[pos, 1])
        end
      end
    end

    @current_text_state = t_CTS.dup
    current_font!

    (width * size / 1000.0)
  end

    # Calculate how wide a given text string will be on a page, at a given
    # size. If +size+ is not specified, PDF::Writer will use the current
    # #font_size. The difference between this method and #text_line_width is
    # that this method will iterate over lines separated with newline
    # characters.
    #
    # The argument list is reversed from earlier versions.
  def text_width(text, size = nil)
    if text.kind_of?(Numeric) and size.kind_of?(String)
      text, size = size, text
      warn PDF::Writer::Lang[:text_width_parameters_reversed] % caller[0]
    end

    if size.nil? or size <= 0
      size = @font_size
    end

    max   = 0

    text.to_s.each do |line|
      width = text_line_width(line, size)
      max = width if width > max
    end
    max
  end

    # Partially calculate the values necessary to sort out the justification
    # of text.
  def adjust_wrapped_text(text, actual, width, x, just)
    adjust  = 0

    case just
    when :left
      nil
    when :right
      x += (width - actual)
    when :center
      x += (width - actual) / 2.0
    when :full
      spaces = text.count(" ")
      adjust = (width - actual) / spaces.to_f if spaces > 0
    end

    [x, adjust]
  end
  private :adjust_wrapped_text

    # Add text to the page, but ensure that it fits within a certain width.
    # If it does not fit then put in as much as possible, breaking at word
    # boundaries; return the remainder. +justification+ and +angle+ can also
    # be specified for the text.
    #
    # This will display the text; if it goes beyond the width +width+, it
    # will backttrack to the previous space or hyphen and return the
    # remainder of the text.
    #
    # +justification+::   :left, :right, :center, or :full
  def add_text_wrap(x, y, width, text, size = nil, justification = :left, angle = 0, test = false)
    if text.kind_of?(Numeric) and size.kind_of?(String)
      text, size = size, text
      warn PDF::Writer::Lang[:add_textw_parameters_reversed] % caller[0]
    end

    if size.nil? or size <= 0
      size = @font_size
    end

      # Need to store the initial text state, as this will change during the
      # width calculation, but will need to be re-set before printing, so
      # that the chars work out right
    t_CTS = @current_text_state.dup

    select_font("Helvetica") if @fonts.empty?
    return "" if width <= 0

    w = brk = brkw = 0
    font = @current_font
    tw = width / size.to_f * 1000

    pos = -1
    loop do
      pos += 1
      break if pos == text.size
      font_change = true
      tag_size, text, font_change = quick_text_tags(text, pos, font_change)
      if tag_size != 0
        if font_change
          current_font!
          font = @current_font
        end
        pos += (tag_size - 1)
      else
        w += char_width(font, text[pos, 1])

        if w > tw # We need to truncate this line
          if brk > 0 # There is somewhere to break the line.
            if text[brk] == " "
              tmp = text[0, brk]
            else
              tmp = text[0, brk + 1]
            end
            x, adjust = adjust_wrapped_text(tmp, brkw, width, x, justification)

              # Reset the text state
            @current_text_state = t_CTS.dup
            current_font!
            add_text(x, y, tmp, size, angle, adjust) unless test
            return text[brk + 1..-1]
          else # just break before the current character
            tmp = text[0, pos]
#           tmpw = (w - char_width(font, text[pos, 1])) * size / 1000.0
            x, adjust = adjust_wrapped_text(tmp, brkw, width, x, justification)

              # Reset the text state
            @current_text_state = t_CTS.dup
            current_font!
            add_text(x, y, tmp, size, angle, adjust) unless test
            return text[pos..-1]
          end
        end

        if text[pos] == ?-
          brk = pos
          brkw = w * size / 1000.0
        end

        if text[pos, 1] == " "
          brk = pos
          ctmp = text[pos]
          ctmp = @fonts[font].differences[ctmp] unless @fonts[font].differences.nil?
          z = @fonts[font].c[tmp].nil? ? 0 : @fonts[font].c[tmp]['WX']
          brkw = (w - z) * size / 1000.0
        end
      end
    end

      # There was no need to break this line.
    justification = :left if justification == :full
    tmpw = (w * size) / 1000.0
    x, adjust = adjust_wrapped_text(text, tmpw, width, x, justification)
      # reset the text state
    @current_text_state = t_CTS.dup
    current_font!
    add_text(x, y, text, size, angle, adjust) unless test
    return ""
  end

    # Saves the state.
  def save_state
    PDF::Writer::State.new do |state|
      state.fill_color        = @current_fill_color
      state.stroke_color      = @current_stroke_color
      state.text_render_style = @current_text_render_style
      state.stroke_style      = @current_stroke_style
      @state_stack.push state
    end
    add_content("\nq")
  end

    # This will be called at a new page to return the state to what it was
    # on the end of the previous page, before the stack was closed down.
    # This is to get around not being able to have open 'q' across pages.
  def reset_state_at_page_start
    @state_stack.each do |state|
      fill_color!         state.fill_color
      stroke_color!       state.stroke_color
      text_render_style!  state.text_render_style
      stroke_style!       state.stroke_style
      add_content("\nq")
    end
  end
  private :reset_state_at_page_start

    # Restore a previously saved state.
  def restore_state
    unless @state_stack.empty?
      state = @state_stack.pop
      @current_fill_color         = state.fill_color
      @current_stroke_color       = state.stroke_color
      @current_text_render_style  = state.text_render_style
      @current_stroke_style       = state.stroke_style
      stroke_style!
    end
    add_content("\nQ")
  end

    # Restore the state at the end of a page.
  def reset_state_at_page_finish
    add_content("\nQ" * @state_stack.size)
  end
  private :reset_state_at_page_finish

    # Make a loose object. The output will go into this object, until it is
    # closed, then will revert to the current one. This object will not
    # appear until it is included within a page. The function will return
    # the object reference.
  def open_object
    @stack << { :contents => @current_contents, :page => @current_page }
    @current_contents = PDF::Writer::Object::Contents.new(self)
    @loose_objects << @current_contents
    yield @current_contents if block_given?
    @current_contents
  end

    # Opens an existing object for editing.
  def reopen_object(id)
    @stack << { :contents => @current_contents, :page => @current_page }
    @current_contents = id
      # if this object is the primary contents for a page, then set the
      # current page to its parent
    @current_page = @current_contents.on_page unless @current_contents.on_page.nil?
    @current_contents
  end

    # Close an object for writing.
  def close_object
    unless @stack.empty?
      obj = @stack.pop
      @current_contents = obj[:contents]
      @current_page = obj[:page]
    end
  end

    # Stop an object from appearing on pages from this point on.
  def stop_object(id)
    obj = @loose_objects.detect { |ii| ii.oid == id.oid }
    @add_loose_objects[obj] = nil
  end

    # After an object has been created, it will only show if it has been
    # added, using this method.
  def add_object(id, where = :this_page)
    obj = @loose_objects.detect { |ii| ii == id }

    if obj and @current_contents != obj
      case where
      when :all_pages, :this_page
        @add_loose_objects[obj] = where if where == :all_pages
        @current_contents.on_page.contents << obj if @current_contents.on_page
      when :even_pages
        @add_loose_objects[obj] = where
        page = @current_contents.on_page
        add_object(id) if (page.info.page_number % 2) == 0
      when :odd_pages
        @add_loose_objects[obj] = where
        page = @current_contents.on_page
        add_object(id) if (page.info.page_number % 2) == 1
      when :all_following_pages
        @add_loose_objects[obj] = :all_pages
      when :following_even_pages
        @add_loose_objects[obj] = :even_pages
      when :following_odd_pages
        @add_loose_objects[obj] = :odd_pages
      end
    end
  end

    # Add content to the documents info object.
  def add_info(label, value = 0)
      # This will only work if the label is one of the valid ones. Modify
      # this so that arrays can be passed as well. If @label is an array
      # then assume that it is key => value pairs else assume that they are
      # both scalar, anything else will probably error.
    if label.kind_of?(Hash)
      label.each { |kk, vv| @info.__send__(kk.downcase.intern, vv) }
    else
      @info.__send__(label.downcase.intern, value)
    end
  end

    # Specify the Destination object where the document should open when it
    # first starts. +style+ must be one of the values detailed for
    # #destinations. The value of +style+ affects the interpretation of
    # +params+. Uses the current page as the starting location.
  def open_here(style, *params)
    open_at(@current_page, style, *params)
  end

    # Specify the Destination object where the document should open when it
    # first starts. +style+ must be one of the following values. The value
    # of +style+ affects the interpretation of +params+. Uses +page+ as the
    # starting location.
  def open_at(page, style, *params)
    d = PDF::Writer::Object::Destination.new(self, page, style, *params)
    @catalog.open_here = d
  end

    # Create a labelled destination within the document. The label is the
    # name which will be used for <c:ilink> destinations.
    #
    # XYZ::   The viewport will be opened at position <tt>(left, top)</tt>
    #         with +zoom+ percentage. +params+ must have three values
    #         representing +left+, +top+, and +zoom+, respectively. If the
    #         values are "null", the current parameter values are unchanged.
    # Fit::   Fit the page to the viewport (horizontal and vertical).
    #         +params+ will be ignored.
    # FitH::  Fit the page horizontally to the viewport. The top of the
    #         viewport is set to the first value in +params+.
    # FitV::  Fit the page vertically to the viewport. The left of the
    #         viewport is set to the first value in +params+.
    # FitR::  Fits the page to the provided rectangle. +params+ must have
    #         four values representing the +left+, +bottom+, +right+, and
    #         +top+ positions, respectively.
    # FitB::  Fits the page to the bounding box of the page. +params+ is
    #         ignored.
    # FitBH:: Fits the page horizontally to the bounding box of the page.
    #         The top position is defined by the first value in +params+.
    # FitBV:: Fits the page vertically to the bounding box of the page. The
    #         left position is defined by the first value in +params+.
  def add_destination(label, style, *params)
    @destinations[label] = PDF::Writer::Object::Destination.new(self, @current_page, style, *params)
  end

    # Set the page mode of the catalog. Must be one of the following:
    # UseNone::     Neither document outline nor thumbnail images are
    #               visible.
    # UseOutlines:: Document outline visible.
    # UseThumbs::   Thumbnail images visible.
    # FullScreen::  Full-screen mode, with no menu bar, window controls, or
    #               any other window visible.
    # UseOC::       Optional content group panel is visible.
    #
  def page_mode=(mode)
    @catalog.page_mode = value
  end

  include Transaction::Simple

    # The width of the currently active column. This will return zero (0) if
    # columns are off.
  attr_reader :column_width
  def column_width #:nodoc:
    return 0 unless @columns_on
    @columns[:width]
  end
    # The gutter between columns. This will return zero (0) if columns are
    # off.
  attr_reader :column_gutter
  def column_gutter #:nodoc:
    return 0 unless @columns_on
    @columns[:gutter]
  end
    # The current column number. Returns zero (0) if columns are off.
  attr_reader :column_number
  def column_number #:nodoc:
    return 0 unless @columns_on
    @columns[:current]
  end
    # The total number of columns. Returns zero (0) if columns are off.
  attr_reader :column_count
  def column_count #:nodoc:
    return 0 unless @columns_on
    @columns[:size]
  end
    # Indicates if columns are currently on.
  def columns?
    @columns_on
  end

    # Starts multi-column output. Creates +size+ number of columns with a
    # +gutter+ PDF unit space between each column.
    #
    # If columns are already started, this will return +false+.
  def start_columns(size = 2, gutter = 10)
      # Start from the current y-position; make the set number of columns.
    return false if @columns_on

    @columns = {
      :current => 1,
      :bot_y   => @y
    }
    @columns_on = true
      # store the current margins
    @columns[:left]   = @left_margin
    @columns[:right]  = @right_margin
    @columns[:top]    = @top_margin
    @columns[:bottom] = @bottom_margin
      # Reset the margins to suit the new columns. Safe enough to assume the
      # first column here, but start from the current y-position.
    @top_margin = @page_height - @y
    @columns[:size]   = size   || 2
    @columns[:gutter] = gutter || 10
    w = absolute_right_margin - absolute_left_margin
    @columns[:width] = (w - ((size - 1) * gutter)) / size.to_f
    @right_margin = @page_width - (@left_margin + @columns[:width])
  end

  def restore_margins_after_columns
    @left_margin   = @columns[:left]
    @right_margin  = @columns[:right]
    @top_margin    = @columns[:top]
    @bottom_margin = @columns[:bottom]
  end
  private :restore_margins_after_columns

    # Turns off multi-column output. If we are in the first column, or the
    # lowest point at which columns were written is higher than the bottom
    # of the page, then the writing pointer will be placed at the lowest
    # point. Otherwise, a new page will be started.
  def stop_columns
    return false unless @columns_on
    @columns_on = false

    @columns[:bot_y] = @y if @y < @columns[:bot_y]

    if (@columns[:bot_y] > @bottom_margin) or @column_number == 1
      @y = @columns[:bot_y]
    else
      start_new_page
    end
    restore_margins_after_columns
    @columns = {}
    true
  end

    # Changes page insert mode. May be called as follows:
    #
    #   pdf.insert_mode         # => current insert mode
    #     # The following four affect the insert mode without changing the
    #     # insert page or insert position.
    #   pdf.insert_mode(:on)    # enables insert mode
    #   pdf.insert_mode(true)   # enables insert mode
    #   pdf.insert_mode(:off)   # disables insert mode
    #   pdf.insert_mode(false)  # disables insert mode
    #
    #     # Changes the insert mode, the insert page, and the insert
    #     # position at the same time.
    #   opts = {
    #     :on       => true,
    #     :page     => :last,
    #     :position => :before
    #   }
    #   pdf.insert_mode(opts)
  def insert_mode(options = {})
    case options
    when :on, true
      @insert_mode = true
    when :off, false
      @insert_mode = false
    else
      return @insert_mode unless options

      @insert_mode = options[:on] unless options[:on].nil?

      unless options[:page].nil?
        if @pageset[options[:page]].nil? or options[:page] == :last
          @insert_page = @pageset[-1]
        else
          @insert_page = @pageset[options[:page]]
        end
      end

      @insert_position = options[:position] if options[:position]
    end
  end
    # Returns or changes the insert page property.
    #
    #   pdf.insert_page         # => current insert page
    #   pdf.insert_page(35)     # insert at page 35
    #   pdf.insert_page(:last)  # insert at the last page
  def insert_page(page = nil)
    return @insert_page unless page
    if page == :last
      @insert_page = @pageset[-1]
    else
      @insert_page = @pageset[page]
    end
  end
    # Changes the #insert_page property to append to the page set.
  def append_page
    insert_mode(:last)
  end
    # Returns or changes the insert position to be before or after the
    # specified page.
    #
    #   pdf.insert_position           # => current insert position
    #   pdf.insert_position(:before)  # insert before #insert_page
    #   pdf.insert_position(:after)   # insert before #insert_page
  def insert_position(position = nil)
    return @insert_position unless position
    @insert_position = position
  end

    # Creates a new page. If multi-column output is turned on, this will
    # change the column to the next greater or create a new page as
    # necessary. If +force+ is true, then a new page will be created even if
    # multi-column output is on.
  def start_new_page(force = false)
    page_required = true

    if @columns_on
        # Check if this is just going to a new column. Increment the column
        # number.
      @columns[:current] += 1

      if @columns[:current] <= @columns[:size] and not force
        page_required = false
        @columns[:bot_y] = @y if @y < @columns[:bot_y]
      else
        @columns[:current] = 1
        @top_margin = @columns[:top]
        @columns[:bot_y] = absolute_top_margin
      end

      w = @columns[:width]
      g = @columns[:gutter]
      n = @columns[:current] - 1
      @left_margin = @columns[:left] + n * (g + w)
      @right_margin = @page_width - (@left_margin + w)
    end

    if page_required or force
        # make a new page, setting the writing point back to the top.
      @y = absolute_top_margin
        # make the new page with a call to the basic class
      if @insert_mode
        id = new_page(true, @insert_page, @insert_position)
        @pageset << id
          # Manipulate the insert options so that inserted pages follow each
          # other
        @insert_page = id
        @insert_position = :after
      else
        @pageset << new_page
      end

    else
      @y = absolute_top_margin
    end
    @pageset
  end

    # Add a new page to the document. This also makes the new page the
    # current active object. This allows for mandatory page creation
    # regardless of multi-column output.
    #
    # For most purposes, #start_new_page is preferred.
  def new_page(insert = false, page = nil, pos = :after)
    reset_state_at_page_finish

    if insert
        # The id from the PDF::Writer class is the id of the contents of the
        # page, not the page object itself. Query that object to find the
        # parent.
      _new_page = PDF::Writer::Object::Page.new(self, { :rpage => page, :pos => pos })
    else
      _new_page = PDF::Writer::Object::Page.new(self)
    end

    reset_state_at_page_start

      # If there has been a stroke or fill color set, transfer them.
    fill_color!
    stroke_color!
    stroke_style!

      # the call to the page object set @current_contents to the present page,
      # so this can be returned as the page id
#   @current_contents
    _new_page
  end

    # Returns the current generic page number. This is based exclusively on
    # the size of the page set.
  def current_page_number
    @pageset.size
  end

    # Put page numbers on the pages from the current page. Place them
    # relative to the coordinates <tt>(x, y)</tt> with the text horizontally
    # relative according to +pos+, which may be <tt>:left</tt>,
    # <tt>:right</tt>, or <tt>:center</tt>. The page numbers will be written
    # on each page using +pattern+.
    #
    # When +pattern+ is rendered, <PAGENUM> will be replaced with the
    # current page number; <TOTALPAGENUM> will be replaced with the total
    # number of pages in the page numbering scheme. The default +pattern+ is
    # "<PAGENUM> of <TOTALPAGENUM>".
    #
    # If +starting+ is non-nil, this is the first page number. The number of
    # total pages will be adjusted to account for this.
    #
    # Each time page numbers are started, a new page number scheme will be
    # started. The scheme number will be returned.
  def start_page_numbering(x, y, size, pos = nil, pattern = nil, starting = nil)
    pos     ||= :left
    pattern ||= "<PAGENUM> of <TOTALPAGENUM>"
    starting  ||= 1

    @page_numbering ||= []
    @page_numbering << (o = {})

    page    = @pageset.size - 1
    o[page] = {
      :x        => x,
      :y        => y,
      :pos      => pos,
      :pattern  => pattern,
      :starting => starting,
      :size     => size,
      :start    => true
    }
    @page_numbering.index(o)
  end

    # Given a particular generic page number +page_num+ (numbered
    # sequentially from the beginning of the page set), return the page
    # number under a particular page numbering +scheme+ (defaults to the
    # first scheme turned on). Returns +nil+ if page numbering is not turned
    # on or if the page is not under the current numbering scheme.
    #
    # This method has been dprecated.
  def which_page_number(page_num, scheme = 0)
    return nil unless @page_numbering

    num   = nil
    start = start_num = 1

    @page_numbering[scheme].each do |kk, vv|
      if kk <= page_num
        if vv.kind_of?(Hash)
          unless vv[:starting].nil?
            start = vv[:starting]
            start_num = kk
            num = page_num - start_num + start
          end
        else
          num = nil
        end
      end
    end
    num
  end

    # Stop page numbering. Returns +false+ if page numbering is off.
    #
    # If +stop_total+ is true, then then the totaling of pages for this page
    # numbering +scheme+ will be stopped as well. If +stop_at+ is
    # <tt>:current</tt>, then the page numbering will stop at this page;
    # otherwise, it will stop at the next page.
    #
    # This method has been dprecated.
  def stop_page_numbering(stop_total = false, stop_at = :current, scheme = 0)
    return false unless @page_numbering

    page = @pageset.size - 1

    @page_numbering[scheme][page] ||= {}
    o = @page_numbering[scheme][page]

    case [ stop_total, stop_at == :current ]
    when [ true, true ]
      o[:stop] = :stop_total
    when [ true, false ]
      o[:stop] = :stop_total_next
    when [ false, true ]
      o[:stop] = :stop_next
      else
      o[:stop] = :stop
    end
  end

  def page_number_search(condition, scheme)
    res = nil
    scheme.each { |page, value| res = page if value[:stop] == condition }
    res
  end
  private :page_number_search

  def add_page_numbers
      # This will go through the @page_numbering array and add the page
      # numbers are required.
    if @page_numbering
      page_count  = @pageset.size
      pn_tmp      = @page_numbering.dup

        # Go through each of the page numbering schemes.
      pn_tmp.each do |scheme|
          # First, find the total pages for this schemes.
        page = page_number_search(:stop_total, scheme)

        if page
          total_pages = page
        else
          page = page_number_search(:stop_total_next, scheme)
          if page
            total_pages = page
          else
            total_pages = page_count
          end
        end

        status  = nil
        delta   = pattern = pos = x = y = size = nil

        @pageset.each_with_index do |page, index|
          next if status.nil? and scheme[index].nil?

          info = scheme[index]
          if info
            if info[:start]
              status = true
            if info[:starting]
                delta = info[:starting] - index
            else
                delta = index
              end

              pattern = info[:pattern]
              pos     = info[:pos]
              x       = info[:x]
              y       = info[:y]
              size    = info[:size]

              # Check for the special case of page numbering starting and
              # stopping on the same page.
              status = :stop_next if info[:stop]
            elsif [:stop, :stop_total].include?(info[:stop])
              status = :stop_now
            elsif status == true and [:stop_next, :stop_total_next].include?(info[:stop])
              status = :stop_next
            end
          end

          if status
              # Add the page numbering to this page
            num   = index + delta.to_i
            total = total_pages + num - index
            patt  = pattern.gsub(/<PAGENUM>/, num.to_s).gsub(/<TOTALPAGENUM>/, total.to_s)
            reopen_object(page.contents.first)

            case pos
            when :left    # Write the page number from x.
              w = 0
            when :right   # Write the page number to x.
              w = text_width(patt, size)
            when :center  # Write the page number around x.
              w = text_width(patt, size) / 2.0
            end
            add_text(x - w, y, patt, size)
            close_object
            status = nil if [ :stop_now, :stop_next ].include?(status)
          end
        end
      end
    end
  end
  private :add_page_numbers

  def preprocess_text(text)
    text
  end
  private :preprocess_text

    # This will add a string of +text+ to the document, starting at the
    # current drawing position. It will wrap to keep within the margins,
    # including optional offsets from the left and the right. The text will
    # go to the start of the next line when a return code "\n" is found.
    #
    # Possible +options+ are:
    # <tt>:font_size</tt>::       The font size to be used. If not
    #                             specified, is either the last font size or
    #                             the default font size of 12 points.
    #                             Setting this value *changes* the current
    #                             #font_size.
    # <tt>:left</tt>::            number, gap to leave from the left margin
    # <tt>:right</tt>::           number, gap to leave from the right margin
    # <tt>:absolute_left</tt>::   number, absolute left position (overrides
    #                             <tt>:left</tt>)
    # <tt>:absolute_right</tt>::  number, absolute right position (overrides
    #                             <tt>:right</tt>)
    # <tt>:justification</tt>::   <tt>:left</tt>, <tt>:right</tt>,
    #                             <tt>:center</tt>, <tt>:full</tt>
    # <tt>:leading</tt>::         number, defines the total height taken by
    #                             the line, independent of the font height.
    # <tt>:spacing</tt>::         a Floating point number, though usually
    #                             set to one of 1, 1.5, 2 (line spacing as
    #                             used in word processing)
    #
    # Only one of <tt>:leading</tt> or <tt>:spacing</tt> should be specified
    # (leading overrides spacing).
    #
    # If the <tt>:test</tt> option is +true+, then this should just check to
    # see if the text is flowing onto a new page or not; returns +true+ or
    # +false+. Note that the new page test is only sensitive to exceeding
    # the bottom margin of the page. It is not known whether the writing of
    # the text will require a new physical page or whether it will require a
    # new column.
  def text(text, options = {})
      # Apply the filtering which will make underlining (and other items)
      # function.
    text = preprocess_text(text)

    options ||= {}

    new_page_required = false
    __y = @y

    if options[:absolute_left]
      left = options[:absolute_left]
    else
      left = @left_margin
      left += options[:left] if options[:left]
    end

    if options[:absolute_right]
      right = options[:absolute_right]
    else
      right = absolute_right_margin
      right -= options[:right] if options[:right]
    end

    size = options[:font_size] || 0
    if size <= 0
      size = @font_size
    else
      @font_size = size
    end

    just = options[:justification] || :left

    if options[:leading] # leading instead of spacing
      height = options[:leading]
    elsif options[:spacing]
      height = options[:spacing] * font_height(size)
    else
      height = font_height(size)
    end

    text.each do |line|
      start = true
      loop do # while not line.empty? or start
        break if (line.nil? or line.empty?) and not start

        start = false

        @y -= height

        if @y < @bottom_margin
          if options[:test]
            new_page_required = true
          else
              # and then re-calc the left and right, in case they have
              # changed due to columns
            start_new_page
            @y -= height

            if options[:absolute_left]
              left = options[:absolute_left]
            else
              left = @left_margin
              left += options[:left] if options[:left]
            end

            if options[:absolute_right]
              right = options[:absolute_right]
            else
              right = absolute_right_margin
              right -= options[:right] if options[:right]
            end
          end
        end

        line = add_text_wrap(left, @y, right - left, line, size, just, 0, options[:test])
      end
    end

    if options[:test]
      @y = __y
      new_page_required
    else
      @y
    end
  end

  def prepress_clip_mark(x, y, angle, mark_length = 18, bleed_size = 12) #:nodoc:
    save_state
    translate_axis(x, y)
    rotate_axis(angle)
    line(0, bleed_size, 0, bleed_size + mark_length).stroke
    line(bleed_size, 0, bleed_size + mark_length, 0).stroke
    restore_state
  end

  def prepress_center_mark(x, y, angle, mark_length = 18, bleed_size = 12) #:nodoc:
    save_state
    translate_axis(x, y)
    rotate_axis(angle)
    half_mark = mark_length / 2.0
    c_x = 0
    c_y = bleed_size + half_mark
    line((c_x - half_mark), c_y, (c_x + half_mark), c_y).stroke
    line(c_x, (c_y - half_mark), c_x, (c_y + half_mark)).stroke
    rad = (mark_length * 0.50) / 2.0
    circle_at(c_x, c_y, rad).stroke
    restore_state
  end

    # Returns the estimated number of lines remaining given the default or
    # specified font size.
  def lines_remaining(font_size = nil)
    font_size ||= @font_size
    remaining = @y - @bottom_margin
    remaining / font_height(font_size).to_f
  end

    # Callback tag relationships. All relationships are of the form
    # "tagname" => CallbackClass.
    #
    # There are three types of tag callbacks:
    # <tt>:pair</tt>::    Paired callbacks, e.g., <c:alink></c:alink>.
    # <tt>:single</tt>::  Single-tag callbacks, e.g., <C:bullet>.
    # <tt>:replace</tt>:: Single-tag replacement callbacks, e.g., <r:xref>.
  TAGS = {
    :pair     => { },
    :single   => { },
    :replace  => { }
  }
  TAGS.freeze

    # A callback to support the formation of clickable links to external
    # locations.
  class TagAlink
      # The default anchored link style.
    DEFAULT_STYLE = {
      :color      => Color::RGB::Blue,
      :text_color => Color::RGB::Blue,
      :draw_line  => true,
      :line_style => { :dash => PDF::Writer::StrokeStyle::SOLID_LINE },
      :factor     => 0.05
    }

    class << self
        # Sets the style for <c:alink> callback underlines that follow. This
        # is expected to be a hash with the following keys:
        #
        # <tt>:color</tt>::       The colour to be applied to the link
        #                         underline. Default is Color::RGB::Blue.
        # <tt>:text_color</tt>::  The colour to be applied to the link text.
        #                         Default is Color::RGB::Blue.
        # <tt>:factor</tt>::      The size of the line, as a multiple of the
        #                         text height. Default is 0.05.
        # <tt>:draw_line</tt>::   Whether to draw the underline as part of
        #                         the link or not. Default is +true+.
        # <tt>:line_style</tt>::  The style modification hash supplied to
        #                         PDF::Writer::StrokeStyle.new. The default
        #                         is a solid line with normal cap, join, and
        #                         miter limit values.
        #
        # Set this to +nil+ to get the default style.
      attr_accessor :style

      def [](pdf, info)
        @style ||= DEFAULT_STYLE.dup

        case info[:status]
        when :start, :start_line
            # The beginning of the link. This should contain the URI for the
            # link as the :params entry, and will also contain the value of
            # :cbid.
          @links ||= {}

          @links[info[:cbid]] = {
            :x         => info[:x],
            :y         => info[:y],
            :angle     => info[:angle],
            :descender => info[:descender],
            :height    => info[:height],
            :uri       => info[:params]["uri"]
          }

          pdf.save_state
          pdf.fill_color @style[:text_color] if @style[:text_color]
          if @style[:draw_line]
            pdf.stroke_color  @style[:color] if @style[:color]
            sz = info[:height] * @style[:factor]
            pdf.stroke_style! StrokeStyle.new(sz, @style[:line_style])
          end
        when :end, :end_line
            # The end of the link. Assume that it is the most recent opening
            # which has closed.
          start = @links[info[:cbid]]
            # Add underlining.
          theta = PDF::Math.deg2rad(start[:angle] - 90.0)
          if @style[:draw_line]
            drop  = start[:height] * @style[:factor] * 1.5
            drop_x = Math.cos(theta) * drop
            drop_y = -Math.sin(theta) * drop
            pdf.move_to(start[:x] - drop_x, start[:y] - drop_y)
            pdf.line_to(info[:x] - drop_x, info[:y] - drop_y).stroke
          end
          pdf.add_link(start[:uri], start[:x], start[:y] +
                       start[:descender], info[:x], start[:y] +
                       start[:descender] + start[:height])
          pdf.restore_state
        end
      end
    end
  end
  TAGS[:pair]["alink"] = TagAlink

    # A callback for creating and managing links internal to the document.
  class TagIlink
    def self.[](pdf, info)
      case info[:status]
      when :start, :start_line
        @links ||= {}
        @links[info[:cbid]] = {
          :x         => info[:x],
          :y         => info[:y],
          :angle     => info[:angle],
          :descender => info[:descender],
          :height    => info[:height],
          :uri       => info[:params]["dest"]
        }
      when :end, :end_line
          # The end of the link. Assume that it is the most recent opening
          # which has closed.
        start = @links[info[:cbid]]
        pdf.add_internal_link(start[:uri], start[:x],
                              start[:y] + start[:descender], info[:x],
                              start[:y] + start[:descender] +
                              start[:height])
      end
    end
  end
  TAGS[:pair]["ilink"] = TagIlink

    # A callback to support underlining.
  class TagUline
      # The default underline style.
    DEFAULT_STYLE = {
      :color      => nil,
      :line_style => { :dash => PDF::Writer::StrokeStyle::SOLID_LINE },
      :factor     => 0.05
    }

    class << self
        # Sets the style for <c:uline> callback underlines that follow. This
        # is expected to be a hash with the following keys:
        #
        # <tt>:factor</tt>::  The size of the line, as a multiple of the
        #                     text height. Default is 0.05.
        #
        # Set this to +nil+ to get the default style.
      attr_accessor :style

      def [](pdf, info)
        @style ||= DEFAULT_STYLE.dup

        case info[:status]
        when :start, :start_line
          @links ||= {}

          @links[info[:cbid]] = {
            :x         => info[:x],
            :y         => info[:y],
            :angle     => info[:angle],
            :descender => info[:descender],
            :height    => info[:height],
            :uri       => nil
          }

          pdf.save_state
          pdf.stroke_color  @style[:color] if @style[:color]
          sz = info[:height] * @style[:factor]
          pdf.stroke_style! StrokeStyle.new(sz, @style[:line_style])
        when :end, :end_line
          start = @links[info[:cbid]]
          theta = PDF::Math.deg2rad(start[:angle] - 90.0)
          drop  = start[:height] * @style[:factor] * 1.5
          drop_x = Math.cos(theta) * drop
          drop_y = -Math.sin(theta) * drop
          pdf.move_to(start[:x] - drop_x, start[:y] - drop_y)
          pdf.line_to(info[:x] - drop_x, info[:y] - drop_y).stroke
          pdf.restore_state
        end
      end
    end
  end
  TAGS[:pair]["uline"] = TagUline

    # A callback function to support drawing of a solid bullet style. Use
    # with <C:bullet>.
  class TagBullet
      # The default bullet color.
    DEFAULT_COLOR = Color::RGB::Black

    class << self
        # Sets the style for <C:bullet> callback bullets that follow.
        # Default is Color::RGB::Black.
        #
        # Set this to +nil+ to get the default colour.
      attr_accessor :color
      def [](pdf, info)
        @color ||= DEFAULT_COLOR

        desc  = info[:descender].abs
        xpos  = info[:x] - (desc * 2.00)
        ypos  = info[:y] + (desc * 1.05)

        pdf.save_state
        ss = StrokeStyle.new(desc)
        ss.cap  = :butt
        ss.join = :miter
        pdf.stroke_style! ss
        pdf.stroke_color @color
        pdf.circle_at(xpos, ypos, 1).stroke
        pdf.restore_state
      end
    end
  end
  TAGS[:single]["bullet"] = TagBullet

    # A callback function to support drawing of a disc bullet style.
  class TagDisc
      # The default disc bullet foreground.
    DEFAULT_FOREGROUND = Color::RGB::Black
      # The default disc bullet background.
    DEFAULT_BACKGROUND = Color::RGB::White
    class << self
        # The foreground color for <C:disc> bullets. Default is
        # Color::RGB::Black.
        #
        # Set to +nil+ to get the default color.
      attr_accessor :foreground
        # The background color for <C:disc> bullets. Default is
        # Color::RGB::White.
        #
        # Set to +nil+ to get the default color.
      attr_accessor :background
      def [](pdf, info)
        @foreground ||= DEFAULT_FOREGROUND
        @background ||= DEFAULT_BACKGROUND

        desc  = info[:descender].abs
        xpos  = info[:x] - (desc * 2.00)
        ypos  = info[:y] + (desc * 1.05)

        ss = StrokeStyle.new(desc)
        ss.cap  = :butt
        ss.join = :miter
        pdf.stroke_style! ss
        pdf.stroke_color @foreground
        pdf.circle_at(xpos, ypos, 1).stroke
        pdf.stroke_color @background
        pdf.circle_at(xpos, ypos, 0.5).stroke
      end
    end
  end
  TAGS[:single]["disc"] = TagDisc

    # Opens a new PDF object for operating against. Returns the object's
    # identifier. To close the object, you'll need to do:
    #   ob = open_new_object  # Opens the object
    #     # do stuff here
    #   close_object          # Closes the PDF document
    #     # do stuff here
    #   reopen_object(ob)     # Reopens the custom object.
    #   close_object          # Closes it.
    #   restore_state         # Returns full control to the PDF document.
    #
    # ... I think. I haven't examined the full details to be sure of what
    # this is doing, but the code works.
  def open_new_object
    save_state
    oid = open_object
    close_object
    add_object(oid)
    reopen_object(oid)
    oid
  end

    # Save the PDF as a file to disk.
  def save_as(name)
    File.open(name, "wb") { |f| f.write self.render }
  end
end
