#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: quickref.rb,v 1.10.2.3 2005/09/07 17:01:14 austin Exp $
#++
require 'pdf/simpletable'

  # = QuickRef
  # A formatting language to create a quick reference sheet. This is a
  # multi-column page in landscape mode that generally has three or four
  # columns. This format may also be used for brochures, but brochure
  # creation requires a bit of management to create properly.
  #
  # == Reference Sheets
  # A three-column reference sheet is generally in the form of:
  #
  # Page 1:
  #   column 1 | column 2 | column 3
  # Page 2:
  #   column 4 | column 5 | column 6
  #
  # The formatting language provided in QuickRef is based around this text
  # flow. The title of the quick reference sheet is in column 1. The two
  # pages are intended to be printed on both sides of pieces of paper so
  # that columns 1 and 6 are matched. This will use a Z-fold that places
  # columns 5 and 6 face to face and columns 2 and 3 face to face. In the
  # folded reference sheet, columns 1 and 4 will be facing out.
  #
  # == Brochures
  # In contrast, brochures differ vastly in their design, although the
  # common brochure is also three columns and either follows the same layout
  # as a reference sheet or uses an overlapping fold.
  #
  # When an overlapping fold is used, the title is typically on column 6
  # (assuming a left-to-right reading order). A short summary will appear on
  # column 4. Contact information about the maker of the brochure is
  # typically in column 5. Columns 1, 2, and 3 will contain the main body of
  # the brochure. The brochure will be folded so that columns 2 and 3 are
  # face to face. After this, column 1 will face column 4 (exposed by the
  # first fold). In the folded brochure, columns 5 and 6 are facing out.
  #
  # == Usage
  #  qr = PDF::QuickRef.new # 3-column LETTER
  #  qr.title "My QuickRef"
  #  qr.h1 "H1 Text"
  #  qr.lines "Text to put after the header."
  #  qr.save_as "MyQuickRef.pdf"
class PDF::QuickRef
  VERSION = '1.1.3'

    # Create the quick reference document. +paper+ is passed unchanged to
    # the PDF::Writer.new; the page is always created landscape. Margins
    # are initialized to 18 points. After some additional initialization is
    # performed, the quick reference document is yielded to an optional
    # block for further configuration. All of this is done before the
    # columns are started.
    #
    # After the columns are started, lines will be drawn between column
    # positions.
  def initialize(paper = "LETTER", columns = 3)
    @pdf  = PDF::Writer.new(:paper => paper, :orientation => :landscape)
    @pdf.margins_pt 18
    @pdf.y = @pdf.absolute_top_margin

    @title_font       = "Times-Roman"
    @heading_font     = "Times-Roman"
    @body_font        = "Times-Roman"
    @code_font        = "Courier"
    @title_font_size = 14
    @h1_font_size    = 11
    @h2_font_size    =  9
    @h3_font_size    =  8
    @h4_font_size    =  7
    @body_font_size  =  6

    @ptab = PDF::SimpleTable.new do |tab|
      tab.column_order.replace %w(one two)

      tab.font_size     = @body_font_size
      tab.show_lines    = :none
      tab.show_headings = false
      tab.orientation   = :center
      tab.position      = :center
    end
    @ltab = PDF::SimpleTable.new do |tab|
      tab.column_order.replace %w(line)

      tab.font_size     = @body_font_size
      tab.show_lines    = :none
      tab.show_headings = false
      tab.orientation   = :center
      tab.position      = :center
    end

    yield self if block_given?

    @pdf.start_columns columns

    @ptab.font_size = @body_font_size
    @ltab.font_size = @body_font_size

    @ptab.maximum_width = @pdf.column_width - 10
    @ltab.maximum_width = @pdf.column_width - 10

      # Put lines between the columns.
    all = @pdf.open_object
    @pdf.save_state
    @pdf.stroke_color! Color::RGB::Black
    @pdf.stroke_style  PDF::Writer::StrokeStyle::DEFAULT
    (1 .. (columns - 1)).each do |ii|
      x = @pdf.left_margin + (@pdf.column_width * ii)
      x += (@pdf.column_gutter * (ii - 0.5))
      @pdf.line(x, @pdf.page_height - @pdf.top_margin, x, @pdf.bottom_margin)
      @pdf.stroke
    end
    @pdf.restore_state
    @pdf.close_object
    @pdf.add_object(all, :all_pages)
  end

    # Access to the raw PDF canvas for normal PDF::Writer configuration.
  attr_reader :pdf

    # The name of the font that will be used for #title text. The default
    # font is Times-Roman.
  attr_accessor :title_font
    # The font encoding for #title text.
  attr_accessor :title_font_encoding
    # The size #title text. The default is 14 points.
  attr_accessor :title_font_size

    # The name of the font that will be used for #h1, #h2, #h3, and #h4
    # text. The default is Times-Roman.
  attr_accessor :heading_font
    # The font encoding for #h1, #h2, #h3, and #h4 text.
  attr_accessor :heading_font_encoding
    # The size #h1 text. The default is 11 points.
  attr_accessor :h1_font_size
    # The size #h2 text. The default is 9 points.
  attr_accessor :h2_font_size
    # The size #h3 text. The default is 8 points.
  attr_accessor :h3_font_size
    # The size #h4 text. The default is 7 points.
  attr_accessor :h4_font_size

    # The name of the font that will be used for #body, #lines, and #pairs
    # text. The default is 'Times-Roman'.
  attr_accessor :body_font
    # The font encoding for #body, #lines, and #pairs text.
  attr_accessor :body_font_encoding
    # The name of the font that will be used for #code, #codelines, and
    # #codepairs text; this is generally a fixed-pitch font. The default is
    # 'Courier'.
  attr_accessor :code_font
    # The font encoding for #code, #codelines, and #codepairs text.
  attr_accessor :code_font_encoding
    # The size #body and #code text. The default is 7 points.
  attr_accessor :body_font_size

    # Creates a two-column zebra-striped table using the #body font. Each
    # line of the text is a separate row; the two columns are separated by
    # tab characters.
  def pairs(text)
    data = text.split($/).map do |line|
      one, two = line.split(/\t/)
      { 'one' => one, 'two' => two }
    end
    @ptab.data.replace data
    @ptab.render_on(@pdf)
    @pdf.text "\n", :font_size => @body_font_size
  end
    # Creates a two-column zebra-striped table using the #code font. Each
    # line of the text is a separate row; the two columns are separated by
    # tab characters.
  def codepairs(text)
    data = text.split($/).map do |line|
      one, two = line.split(/\t/)
      { 'one' => one, 'two' => two }
    end
    @ptab.data.replace data
    use_code_font
    @ptab.render_on(@pdf)
    use_body_font
    @pdf.text "\n", :font_size => @body_font_size
  end
    # Creates a one-column zebra-striped table using the #body font. Each
    # line of the text is a separate row.
  def lines(text)
    data = text.split($/).map { |line| { "line" => line } }
    @ltab.data.replace data
    @ltab.render_on(@pdf)
    @pdf.text "\n", :font_size => @body_font_size
  end
    # Creates a one-column zebra-striped table using the #code font. Each
    # line of the text is a separate row.
  def codelines(text)
    data = text.split($/).map { |line| { "line" => line } }
    @ltab.data.replace data
    use_code_font
    @ltab.render_on(@pdf)
    use_body_font
    @pdf.text "\n", :font_size => @body_font_size
  end

    # Change the current font to the #title font.
  def use_title_font
    @pdf.select_font @title_font, @title_font_encoding
  end
    # Change the current font to the heading font (used normally by #h1,
    # #h2, #h3, and #h4|).
  def use_heading_font
    @pdf.select_font @heading_font, @heading_font_encoding
  end
    # Change the current font to the #body font.
  def use_body_font
    @pdf.select_font @body_font, @body_font_encoding
  end
    # Change the current font to the #code font.
  def use_code_font
    @pdf.select_font @code_font, @code_font_encoding
  end

    # Writes the +text+ with the #title_font and #title_font_size centered
    # in the column. After the title has been written, an #hline will be
    # drawn under the title. The font is set to #body_font after the title
    # is drawn.
  def title(text)
    use_title_font
    @pdf.text text, :font_size => @title_font_size, :justification => :center
    use_body_font
    hline
  end
    # Writes the +text+ with the #heading_font and #h1_font_size left
    # justified in the column. The font is set to #body_font after the
    # heading is drawn.
  def h1(text)
    use_heading_font
    @pdf.text text, :font_size => @h1_font_size
    use_body_font
  end
    # Writes the +text+ with the #heading_font and #h2_font_size left
    # justified in the column. The font is set to #body_font after the
    # heading is drawn.
  def h2(text)
    use_heading_font
    @pdf.text "<i>#{text}</i>", :font_size => @h2_font_size
    use_body_font
  end
    # Writes the +text+ with the #heading_font and #h3_font_size left
    # justified in the column. The font is set to #body_font after the
    # heading is drawn.
  def h3(text)
    use_heading_font
    @pdf.text "<i>#{text}</i>", :font_size => @h3_font_size
    use_body_font
  end
    # Writes the +text+ with the #heading_font and #h4_font_size left
    # justified in the column. The font is set to #body_font after the
    # heading is drawn.
  def h4(text)
    use_heading_font
    @pdf.text "<b><i>#{text}</i></b>", :font_size => @h4_font_size
    use_body_font
  end
    # Writes body text. Paragraphs will be reflowed for optimal placement of
    # text. Text separated by two line separators (e.g., \n\n, although the
    # separator is platform dependent). The text will be placed with full
    # justification.
  def body(text)
      # Transform the text a little.
    paras = text.split(%r(#{$/}{2}))
    paras.map! { |para| para.split($/).join(" ").squeeze(" ") }
    text = paras.join("\n\n")

    @pdf.text "#{text}\n", :font_size => @body_font_size, :justification => :full
  end
    # Writes code text. Newlines and spaces will be preserved.
  def pre(text)
    use_code_font
    @pdf.text "#{text}\n", :font_size => @body_font_size
    use_body_font
  end

    # Draws a horizontal line with the specified style and colour.
  def hline(style = PDF::Writer::StrokeStyle::DEFAULT,
            color = Color::RGB::Black)
    @pdf.y -= 2.5
    @pdf.save_state
    @pdf.stroke_style  style
    @pdf.stroke_color! color
    x0 = @pdf.left_margin
    x1 = @pdf.left_margin + pdf.column_width
    @pdf.line(x0, @pdf.y, x1, @pdf.y)
    @pdf.stroke
    @pdf.restore_state
    @pdf.y -= 2.5
  end

    # Writes the Quick Reference to disk.
  def save_as(filename)
    @pdf.save_as(filename)
  end

    # Generates the PDF document as a string.
  def render
    @pdf.render
  end

  alias to_s render

    # Creates a QuickRef document and then calls #instance_eval on the
    # document. This allows for a more natural use of the QuickRef class as
    # a DSL for creating these documents.
    #
    # === Using #make
    #  PDF::QuickRef.make do # 3-column LETTER
    #    title "My QuickRef"
    #    h1 "H1 Text"
    #    lines "Text to put after the header."
    #    save_as "MyQuickRef.pdf"
    #  end
  def self.make(*args, &block)
    qr = PDF::QuickRef.new(*args)
    qr.__send__(:instance_eval, &block)
  end
end
