#! /usr/bin/env ruby
#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: techbook.rb,v 1.17.2.1 2005/08/25 03:38:05 austin Exp $
#++
require 'pdf/simpletable'
require 'pdf/charts/stddev'

require 'cgi'
require 'open-uri'

begin
  require 'progressbar'
rescue LoadError
  class ProgressBar #:nodoc:
    def initialize(*args)
    end
    def method_missing(*args)
    end
  end
end

require 'optparse'
require 'ostruct'

  # = PDF::TechBook
  # The TechBook class is a markup language interpreter. This will read a
  # file containing the "TechBook" markukp, described below, and create a
  # PDF document from it. This is intended as a complete document language,
  # but it does have a number of limitations.
  #
  # The TechBook markup language and class are used to format the
  # PDF::Writer manual, represented in the distrubtion by the file
  # "manual.pwd".
  #
  # The TechBook markup language is *primarily* stream-oriented with
  # awareness of lines. That is to say that the document will be read and
  # generated from beginning to end in the order of the markup stream.
  #
  # == TechBook Markup
  # TechBook markup is relatively simple. The simplest markup is no markup
  # at all (flowed paragraphs). This means that two lines separated by a
  # single line separator will be treaed as part of the same paragraph and
  # formatted appropriately by PDF::Writer. Paragaphs are terminated by
  # empty lines, valid line markup directives, or valid headings.
  #
  # Certain XML entitites will need to be escaped as they would in normal
  # XML usage, that is, &lt; must be written as &amp;lt;; &gt; must be
  # written as &amp;gt;; and &amp; must be written as &amp;amp;.
  #
  # Comments, headings, and directives are line-oriented where the first
  # mandatory character is in the first column of the document and take up
  # the whole line. Styling and callback tags may appear anywhere in the
  # text.
  #
  # === Comments
  # Comments begin with the hash-mark ('#') at the beginning of the line.
  # Comment lines are ignored.
  #
  # === Styling and Callback Tags
  # Within normal, preserved, or code text, or in headings, HTML-like markup
  # may be used for bold (&lt;b&gt;) and italic (&lt;i&gt;) text. TechBook
  # supports standard PDF::Writer callback tags (<c:alink>, <c:ilink>,
  # <C:bullet/>, and <C:disc/>) and adds two new ones (<r:xref/>,
  # <C:tocdots/>).
  #
  # <tt>&lt;r:xref/></tt>::     Creates an internal document link to the
  #                             named cross-reference destination. Works
  #                             with the heading format (see below). See
  #                             #tag_xref_replace for more information.
  # <tt>&lt;C:tocdots/></tt>::  This is used internally to create and
  #                             display a row of dots between a table of
  #                             contents entry and the page number to which
  #                             it refers. This is used internally by
  #                             TechBook.
  #
  # === Directives
  # Directives begin with a period ('.') and are followed by a letter
  # ('a'..'z') and then any combination of word characters ('a'..'z',
  # '0'..'9', and '_'). Directives are case-insensitive. A directive may
  # have arguments; if there are arguments, they must follow the directive
  # name after whitespace. After the arguments for a directive, if any, all
  # other text is ignored and may be considered a comment.
  #
  # ==== <tt>.newpage [force]</tt>
  # The <tt>.newpage</tt> directive starts a new page. If multicolumn mode
  # is on, a new column will be started if the current column is not the
  # last column. If the optional argument <tt>force</tt> follows the
  # <tt>.newpage</tt> directive, a new page will be started even if
  # multicolumn mode is on.
  #
  #   .newpage
  #   .newpage force
  #
  # ==== <tt>.pre</tt>, <tt>.endpre</tt>
  # The <tt>.pre</tt> and <tt>.endpre</tt> directives enclose a block of
  # text with preserved newlines. This is similar to normal text, but the
  # lines in the <tt>.pre</tt> block are not flowed together. This is useful
  # for poetic forms or other text that must end when each line ends.
  # <tt>.pre</tt> blocks may not be nested in any other formatting block.
  # When an <tt>.endpre</tt> directive is encountered, the text format will
  # be returned to normal (flowed text) mode.
  #
  #   .pre
  #   The Way that can be told of is not the eternal Way;
  #   The name that can be named is not the eternal name.
  #   The Nameless is the origin of Heaven and Earth;
  #   The Named is the mother of all things.
  #   Therefore let there always be non-being,
  #     so we may see their subtlety,
  #   And let there always be being,
  #     so we may see their outcome.
  #   The two are the same,
  #   But after they are produced,
  #     they have different names.
  #   .endpre
  #
  # ==== <tt>.code</tt>, <tt>.endcode</tt>
  # The <tt>.code</tt> and <tt>.endcode</tt> directives enclose a block of
  # text with preserved newlines. In addition, the font is changed from the
  # normal #techbook_textfont to #techbook_codefont. The #techbook_codefont
  # is normally a fixed pitched font and defaults to Courier. At the end of
  # the code block, the text state is restored to its prior state, which
  # will either be <tt>.pre</tt> or normal. 
  #
  #   .code
  #   require 'pdf/writer'
  #   PDF::Writer.prepress # US Letter, portrait, 1.3, prepress
  #   .endcode
  #
  # ==== <tt>.blist</tt>, <tt>.endblist</tt>
  # These directives enclose a bulleted list block. Lists may be nested
  # within other text states. If lists are nested, each list will be
  # appropriately indented. Each line in the list block will be treated as a
  # single list item with a bullet inserted in front using either the
  # <C:bullet/> or <C:disc/> callbacks. Nested lists are successively
  # indented. <tt>.blist</tt> directives accept one optional argument, the
  # name of the type of bullet callback desired (e.g., 'bullet' for
  # <C:bullet/> and 'disc' for <C:disc/>).
  #
  #   .blist
  #   Item 1
  #   .blist disc
  #   Item 1.1
  #   .endblist
  #   .endblist
  #
  # ==== <tt>.eval</tt>, <tt>.endeval</tt>
  # With these directives, the block enclosed will collected and passed to
  # Ruby's Kernel#eval. <tt>.eval</tt> blocks may be present within normal
  # text, <tt>.pre</tt>, <tt>.code</tt>, and <tt>.blist</tt> blocks. No
  # other block may be embedded within an <tt>.eval</tt> block.
  #
  #   .eval
  #   puts "Hello"
  #   .endeval
  #
  # ==== <tt>.columns</tt>
  # Multi-column output is controlled with this directive, which accepts one
  # or two parameters. The first parameter is mandatory and is either the
  # number of columns (2 or more) or the word 'off' (turning off
  # multi-column output). When starting multi-column output, a second
  # parameter with the gutter size may be specified.
  #
  #   .columns 3
  #   Column 1
  #   .newpage
  #   Column 2
  #   .newpage
  #   Column 3
  #   .columns off
  #
  # ==== <tt>.toc</tt>
  # This directive is used to tell TechBook to generate a table of contents
  # after the first page (assumed to be a title page). If this is not
  # present, then a table of contents will not be generated.
  #
  # ==== <tt>.author</tt>, <tt>.title</tt>, <tt>.subject</tt>, <tt>.keywords</tt>
  # Sets values in the PDF information object. The arguments -- to the end
  # of the line -- are used to populate the values.
  #
  # ==== <tt>.done</tt>
  # Stops the processing of the document at this point.
  #
  # === Headings
  # Headings begin with a number followed by the rest of the heading format.
  # This format is "#<heading-text>" or "#<heading-text>xref_name". TechBook
  # supports five levels of headings. Headings may include markup, but
  # should not exceed a single line in size; those headings which have boxes
  # as part of their layout are not currently configured to work with
  # multiple lines of heading output. If an xref_name is specified, then the
  # &lt;r:xref> tag can use this name to find the target for the heading. If
  # xref_name is not specified, then the "name" associated with the heading
  # is the index of the order of insertion. The xref_name is case sensitive.
  #
  #   1<Chapter>xChapter
  #   2<Section>Section23
  #   3<Subsection>
  #   4<Subsection>
  #   5<Subsection>
  #
  # ==== Heading Level 1
  # First level headings are generally chapters. As such, the standard
  # implementation of the heading level 1 method (#__heading1), will be
  # rendered as "chapter#. heading-text" in centered white on a black
  # background, at 26 point (H1_STYLE). First level headings are added to
  # the table of contents.
  #
  # ==== Heading Level 2
  # Second level headings are major sections in chapters. The headings are
  # rendered by default as black on 80% grey, left-justified at 18 point
  # (H2_STYLE). The text is unchanged (#__heading2). Second level headings
  # are added to the table of contents.
  #
  # ==== Heading Level 3, 4, and 5
  # The next three heading levels are used for varying sections within
  # second level chapter sections. They are rendered by default in black on
  # the background (there is no bar) at 18, 14, and 12 points, respectively
  # (H3_STYLE, H4_STYLE, and H5_STYLE). Third level headings are bold-faced
  # (#__heading3); fourth level headings are italicised (#__heading4), and
  # fifth level headings are underlined (#__heading5).
  #
class PDF::TechBook < PDF::Writer
  attr_accessor :table_of_contents
  attr_accessor :chapter_number

    # A stand-alone replacement callback that will return an internal link
    # with either the name of the cross-reference or the page on which the
    # cross-reference appears as the label. If the page number is not yet
    # known (when the cross-referenced item has not yet been rendered, e.g.,
    # forward-references), the label will be used in any case.
    #
    # The parameters are:
    # name::  The name of the cross-reference.
    # label:: Either +page+, +title+, or +text+. +page+ will <em>not</em> be
    #         used for forward references; only +title+ or +text+ will be
    #         used.
    # text::  Required if +label+ has a value of +text+. Ignored if +label+
    #         is +title+, optional if +label+ is +page+. This value will be
    #         used as the display text for the internal link. +text+
    #         takes precedence over +title+ if +label+ is +page+.
  class TagXref
    def self.[](pdf, params)
      name  = params["name"]
      item  = params["label"]
      text  = params["text"]

      xref = pdf.xref_table[name]
      if xref
        case item
        when 'page'
          label = xref[:page]
          if text.nil? or text.empty?
            label ||= xref[:title]
          else
            label ||= text
          end
        when 'title'
          label = xref[:title]
        when 'text'
          label = text
        end

        "<c:ilink dest='#{xref[:xref]}'>#{label}</c:ilink>"
      else
        warn PDF::Writer::Lang[:techbook_unknown_xref] % [ name ]
        PDF::Writer::Lang[:techbook_unknown_xref] % [ name ]
      end
    end
  end
  PDF::Writer::TAGS[:replace]["xref"] = PDF::TechBook::TagXref

    # A stand-alone callback that draws a dotted line over to the right and
    # appends a page number. The info[:params] will be like a standard XML
    # tag with three named parameters:
    #
    # level:: The table of contents level that corresponds to a particular
    #         style. In the current TechBook implementation, there are only
    #         two levels. Level 1 uses a 16 point font and #level1_style;
    #         level 2 uses a 12 point font and #level2_style.
    # page::  The page number that is to be printed.
    # xref::  The target destination that will be used as a link.
    #
    # All parameters are required.
  class TagTocDots
    DEFAULT_L1_STYLE = {
      :width      => 1,
      :cap        => :round,
      :dash       => { :pattern => [ 1, 3 ], :phase => 1 },
      :font_size  => 16
    }

    DEFAULT_L2_STYLE = {
      :width      => 1,
      :cap        => :round,
      :dash       => { :pattern => [ 1, 5 ], :phase => 1 },
      :font_size  => 12
    }

    class << self
        # Controls the level 1 style.
      attr_accessor :level1_style
        # Controls the level 2 style.
      attr_accessor :level2_style

      def [](pdf, info)
        if @level1_style.nil?
          @level1_style = sh = DEFAULT_L1_STYLE
          ss      = PDF::Writer::StrokeStyle.new(sh[:width])
          ss.cap  = sh[:cap] if sh[:cap]
          ss.dash = sh[:dash] if sh[:dash]
          @_level1_style = ss
        end
        if @level2_style.nil?
          @level2_style = sh = DEFAULT_L2_STYLE
          ss      = PDF::Writer::StrokeStyle.new(sh[:width])
          ss.cap  = sh[:cap] if sh[:cap]
          ss.dash = sh[:dash] if sh[:dash]
          @_level2_style = ss
        end

        level = info[:params]["level"]
        page  = info[:params]["page"]
        xref  = info[:params]["xref"]

        xpos = 520

        pdf.save_state
        case level
        when "1"
          pdf.stroke_style @_level1_style
          size = @level1_style[:font_size]
        when "2"
          pdf.stroke_style @_level2_style
          size = @level2_style[:font_size]
        end

        page = "<c:ilink dest='#{xref}'>#{page}</c:ilink>" if xref

        pdf.line(xpos, info[:y], info[:x] + 5, info[:y]).stroke
        pdf.restore_state
        pdf.add_text(xpos + 5, info[:y], page, size)
      end
    end
  end
  PDF::Writer::TAGS[:single]["tocdots"] = PDF::TechBook::TagTocDots

  attr_reader :xref_table
  def __build_xref_table(data)
    headings = data.grep(HEADING_FORMAT_RE)

    @xref_table = {}

    headings.each_with_index do |text, idx|
      level, label, name = HEADING_FORMAT_RE.match(text).captures

      xref = "xref#{idx}"

      name ||= idx.to_s
      @xref_table[name] = {
        :title  => __send__("__heading#{level}", label),
        :page   => nil,
        :level  => level.to_i,
        :xref   => xref
      }
    end
  end
  private :__build_xref_table

  def __render_paragraph
    unless @techbook_para.empty?
      techbook_text(@techbook_para.squeeze(" "))
      @techbook_para.replace ""
    end
  end
  private :__render_paragraph

  LINE_DIRECTIVE_RE = %r{^\.([a-z]\w+)(?:$|\s+(.*)$)}io #:nodoc:

  def techbook_find_directive(line)
    directive = nil
    arguments = nil
    dmatch = LINE_DIRECTIVE_RE.match(line)
    if dmatch
      directive = dmatch.captures[0].downcase.chomp
      arguments = dmatch.captures[1]
    end
    [directive, arguments]
  end
  private :techbook_find_directive

  H1_STYLE = {
    :background     => Color::RGB::Black,
    :foreground     => Color::RGB::White,
    :justification  => :center,
    :font_size      => 26,
    :bar            => true
  }
  H2_STYLE = {
    :background     => Color::RGB::Grey80,
    :foreground     => Color::RGB::Black,
    :justification  => :left,
    :font_size      => 18,
    :bar            => true
  }
  H3_STYLE = {
    :background     => Color::RGB::White,
    :foreground     => Color::RGB::Black,
    :justification  => :left,
    :font_size      => 18,
    :bar            => false
  }
  H4_STYLE = {
    :background     => Color::RGB::White,
    :foreground     => Color::RGB::Black,
    :justification  => :left,
    :font_size      => 14,
    :bar            => false
  }
  H5_STYLE = {
    :background     => Color::RGB::White,
    :foreground     => Color::RGB::Black,
    :justification  => :left,
    :font_size      => 12,
    :bar            => false
  }
  def __heading1(heading)
    @chapter_number ||= 0
    @chapter_number = @chapter_number.succ
    "#{chapter_number}. #{heading}"
  end
  def __heading2(heading)
    heading
  end
  def __heading3(heading)
    "<b>#{heading}</b>"
  end
  def __heading4(heading)
    "<i>#{heading}</i>"
  end
  def __heading5(heading)
    "<c:uline>#{heading}</c:uline>"
  end

  HEADING_FORMAT_RE = %r{^([\d])<(.*)>([a-z\w]+)?$}o #:nodoc:

  def techbook_heading(line)
    head = HEADING_FORMAT_RE.match(line)
    if head
      __render_paragraph

      @heading_num ||= -1
      @heading_num += 1

      level, heading, name = head.captures
      level = level.to_i

      name ||= @heading_num.to_s
      heading = @xref_table[name]

      style   = self.class.const_get("H#{level}_STYLE")

      start_transaction(:heading_level)
      ok = false

      loop do # while not ok
        break if ok
        this_page = pageset.size

        save_state

        if style[:bar]
          fill_color style[:background]
          fh = font_height(style[:font_size]) * 1.01
          fd = font_descender(style[:font_size]) * 1.01
          x = absolute_left_margin
          w = absolute_right_margin - absolute_left_margin
          rectangle(x, y - fh + fd, w, fh).fill
        end

        fill_color style[:foreground]
        text(heading[:title], :font_size => style[:font_size],
             :justification => style[:justification])

        restore_state

        if (pageset.size == this_page)
          commit_transaction(:heading_level)
          ok = true
        else
            # We have moved onto a new page. This is bad, as the background
            # colour will be on the old one.
          rewind_transaction(:heading_level)
          start_new_page
        end
      end

      heading[:page] = which_page_number(current_page_number)

      case level
      when 1, 2
        @table_of_contents << heading
      end

      add_destination(heading[:xref], 'FitH', @y + font_height(style[:font_size]))
    end
    head
  end
  private :techbook_heading

  def techbook_parse(document, progress = nil)
    @table_of_contents = []

    @toc_title          = "Table of Contents"
    @gen_toc            = false
    @techbook_code      = ""
    @techbook_para      = ""
    @techbook_fontsize  = 12
    @techbook_textopt   = { :justification => :full }
    @techbook_lastmode  = @techbook_mode = :normal

    @techbook_textfont  = "Times-Roman"
    @techbook_codefont  = "Courier"

    @blist_info         = []

    @techbook_line__    = 0

    __build_xref_table(document)

    document.each do |line|
    begin
      progress.inc if progress
      @techbook_line__ += 1

      next if line =~ %r{^#}o

      directive, args = techbook_find_directive(line)
      if directive
          # Just try to call the method/directive. It will be far more
          # common to *find* the method than not to.
        res = __send__("techbook_directive_#{directive}", args) rescue nil
        break if :break == res 
        next
      end

      case @techbook_mode
      when :eval
        @techbook_code << line << "\n"
        next
      when :code
        techbook_text(line)
        next
      when :blist
        line = "<C:#{@blist_info[-1][:style]}/>#{line}"
        techbook_text(line)
        next
      end

      next if techbook_heading(line)

      if :preserved == @techbook_mode
        techbook_text(line)
        next
      end

      line.chomp!

      if line.empty?
        __render_paragraph
        techbook_text("\n")
      else
        @techbook_para << " " unless @techbook_para.empty?
        @techbook_para << line
      end
    rescue Exception => ex
      $stderr.puts PDF::Writer::Lang[:techbook_exception] % [ ex, @techbook_line ]
      raise
    end
    end
  end

  def techbook_toc(progress = nil)
    insert_mode :on
    insert_position :after
    insert_page 1
    start_new_page

    style = H1_STYLE
    save_state

    if style[:bar]
      fill_color    style[:background]
      fh = font_height(style[:font_size]) * 1.01
      fd = font_descender(style[:font_size]) * 1.01
      x = absolute_left_margin
      w = absolute_right_margin - absolute_left_margin
      rectangle(x, y - fh + fd, w, fh).fill
    end

    fill_color  style[:foreground]
    text(@toc_title, :font_size => style[:font_size],
         :justification => style[:justification])

    restore_state

    self.y += font_descender(style[:font_size])#* 0.5

    right = absolute_right_margin

      # TODO -- implement tocdots as a replace tag and a single drawing tag.
    @table_of_contents.each do |entry|
      progress.inc if progress

      info =  "<c:ilink dest='#{entry[:xref]}'>#{entry[:title]}</c:ilink>"
      info << "<C:tocdots level='#{entry[:level]}' page='#{entry[:page]}' xref='#{entry[:xref]}'/>"

      case entry[:level]
      when 1
        text info, :font_size => 16, :absolute_right => right
      when 2
        text info, :font_size => 12, :left => 50, :absolute_right => right
      end
    end
  end

  attr_accessor :techbook_codefont
  attr_accessor :techbook_textfont
  attr_accessor :techbook_encoding
  attr_accessor :techbook_fontsize

    # Start a new page: .newpage
  def techbook_directive_newpage(args)
    __render_paragraph

    if args =~ /^force/
      start_new_page true
    else
      start_new_page
    end
  end

    # Preserved newlines: .pre
  def techbook_directive_pre(args)
    __render_paragraph
    @techbook_mode = :preserved
  end

    # End preserved newlines: .endpre
  def techbook_directive_endpre(args)
    @techbook_mode = :normal
  end

    # Code: .code
  def techbook_directive_code(args)
    __render_paragraph
    select_font @techbook_codefont, @techbook_encoding
    @techbook_lastmode, @techbook_mode = @techbook_mode, :code
    @techbook_textopt  = { :justification => :left, :left => 20, :right => 20 }
    @techbook_fontsize = 10
  end

    # End Code: .endcode
  def techbook_directive_endcode(args)
    select_font @techbook_textfont, @techbook_encoding
    @techbook_lastmode, @techbook_mode = @techbook_mode, @techbook_lastmode
    @techbook_textopt  = { :justification => :full }
    @techbook_fontsize = 12
  end

    # Eval: .eval
  def techbook_directive_eval(args)
    __render_paragraph
    @techbook_lastmode, @techbook_mode = @techbook_mode, :eval
  end

    # End Eval: .endeval
  def techbook_directive_endeval(args)
    save_state

    thread = Thread.new do
      begin
        @techbook_code.untaint
        pdf = self
        eval @techbook_code
      rescue Exception => ex
        err = PDF::Writer::Lang[:techbook_eval_exception]
        $stderr.puts err % [ @techbook_line__, ex, ex.backtrace.join("\n") ]
        raise ex
      end
    end
    thread.abort_on_exception = true
    thread.join

    restore_state
    select_font @techbook_textfont, @techbook_encoding

    @techbook_code = ""
    @techbook_mode, @techbook_lastmode = @techbook_lastmode, @techbook_mode
  end

    # Done. Stop parsing: .done
  def techbook_directive_done(args)
    unless @techbook_code.empty?
      $stderr.puts PDF::Writer::Lang[:techbook_code_not_empty]
      $stderr.puts @techbook_code
    end
    __render_paragraph
    :break
  end

    # Columns. .columns <number-of-columns>|off
  def techbook_directive_columns(args)
    av = /^(\d+|off)(?: (\d+))?(?: .*)?$/o.match(args)
    unless av
      $stderr.puts PDF::Writer::Lang[:techbook_bad_columns_directive] % args
      raise ArgumentError
    end
    cols = av.captures[0]

      # Flush the paragraph cache.
    __render_paragraph

    if cols == "off" or cols.to_i < 2
      stop_columns
    else
      if av.captures[1]
        start_columns(cols.to_i, av.captures[1].to_i)
      else
        start_columns(cols.to_i)
      end
    end
  end

  def techbook_directive_toc(args)
    @toc_title  = args unless args.empty?
    @gen_toc    = true
  end

  def techbook_directive_author(args)
    info.author = args
  end
  
  def techbook_directive_title(args)
    info.title  = args
  end

  def techbook_directive_subject(args)
    info.subject  = args
  end

  def techbook_directive_keywords(args)
    info.keywords = args
  end

  LIST_ITEM_STYLES = %w(bullet disc)

  def techbook_directive_blist(args)
    __render_paragraph
    sm = /^(\w+).*$/o.match(args)
    style = sm.captures[0] if sm
    style = "bullet" unless LIST_ITEM_STYLES.include?(style)

    @blist_factor = @left_margin * 0.10 if @blist_info.empty?

    info = {
      :left_margin  => @left_margin,
      :style        => style
    }
    @blist_info << info
    @left_margin += @blist_factor

    @techbook_lastmode, @techbook_mode = @techbook_mode, :blist if :blist != @techbook_mode
  end

  def techbook_directive_endblist(args)
    self.left_margin = @blist_info.pop[:left_margin]
    @techbook_lastmode, @techbook_mode = @techbook_mode, @techbook_lastmode if @blist_info.empty?
  end

  def generate_table_of_contents?
    @gen_toc
  end

  attr_accessor :techbook_source_dir

  def self.run(args)
    config = OpenStruct.new
    config.regen      = false
    config.cache      = true
    config.compressed = false

    opts = OptionParser.new do |opt|
      opt.banner    = PDF::Writer::Lang[:techbook_usage_banner] % [ File.basename($0) ]
      PDF::Writer::Lang[:techbook_usage_banner_1].each do |ll|
        opt.separator "  #{ll}"
      end
      opt.on('-f', '--force-regen', *PDF::Writer::Lang[:techbook_help_force_regen]) { config.regen = true }
      opt.on('-n', '--no-cache', *PDF::Writer::Lang[:techbook_help_no_cache]) { config.cache = false }
      opt.on('-z', '--compress', *PDF::Writer::Lang[:techbook_help_compress]) { config.compressed = true }
      opt.on_tail ""
      opt.on_tail("--help", *PDF::Writer::Lang[:techbook_help_help]) { $stderr << opt; exit(0) }
    end
    opts.parse!(args)

    config.document = args[0]

    unless config.document
      config.document = "manual.pwd"
      unless File.exist?(config.document)
        dirn = File.dirname(__FILE__)
        config.document = File.join(dirn, File.basename(config.document))
        unless File.exist?(config.document)
          dirn = File.join(dirn, "..")
          config.document = File.join(dirn, File.basename(config.document))
          unless File.exist?(config.document)
            dirn = File.join(dirn, "..")
            config.document = File.join(dirn,
                                        File.basename(config.document))
            unless File.exist?(config.document)
              $stderr.puts PDF::Writer::Lang[:techbook_cannot_find_document]
              exit(1)
            end
          end
        end
      end

      $stderr.puts PDF::Writer::Lang[:techbook_using_default_doc] % config.document
    end

    dirn = File.dirname(config.document)
    extn = File.extname(config.document)
    base = File.basename(config.document, extn)

    files = {
      :document => config.document,
      :cache    => "#{base}._mc",
      :pdf      => "#{base}.pdf"
    }

    unless config.regen
      if File.exist?(files[:cache])
        _tm_doc = File.mtime(config.document)
        _tm_prg = File.mtime(__FILE__)
        _tm_cch = File.mtime(files[:cache])
        
          # If the cached file is newer than either the document or the
          # class program, then regenerate.
        if (_tm_doc < _tm_cch) and (_tm_prg < _tm_cch)
          $stderr.puts PDF::Writer::Lang[:techbook_using_cached_doc] % File.basename(files[:cache])
          pdf = File.open(files[:cache], "rb") { |cf| Marshal.load(cf.read) }
          pdf.save_as(files[:pdf])
          File.open(files[:pdf], "wb") { |pf| pf.write pdf.render }
          exit(0)
        else
          $stderr.puts PDF::Writer::Lang[:techbook_regenerating]
        end
      end
    else
      $stderr.puts PDF::Writer::Lang[:techbook_ignoring_cache] if File.exist?(files[:cache])
    end

      # Create the manual object.
    pdf = PDF::TechBook.new
    pdf.compressed = config.compressed
    pdf.techbook_source_dir = File.expand_path(dirn)

    document = open(files[:document]) { |io| io.read.split($/) }
    progress = ProgressBar.new(base.capitalize, document.size)
    pdf.techbook_parse(document, progress)
    progress.finish

    if pdf.generate_table_of_contents?
      progress = ProgressBar.new("TOC", pdf.table_of_contents.size)
      pdf.techbook_toc(progress)
      progress.finish
    end

    if config.cache
      File.open(files[:cache], "wb") { |f| f.write Marshal.dump(pdf) }
    end

    pdf.save_as(files[:pdf])
  end

  def techbook_text(line)
    opt = @techbook_textopt.dup
    opt[:font_size] = @techbook_fontsize
    text(line, opt)
  end

  instance_methods.grep(/^techbook_directive_/).each do |mname|
    private mname.intern
  end
end
