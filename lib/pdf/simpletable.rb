#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: simpletable.rb,v 1.13.2.2 2005/09/07 17:01:14 austin Exp $
#++
require 'pdf/writer'
require 'transaction/simple/group'

  # This class will create tables with a relatively simple API and internal
  # implementation.
class PDF::SimpleTable
  VERSION = '1.1.3'

  include Transaction::Simple

    # Defines formatting options for a column.
  class Column
    def initialize(name)
      @name = name

      yield self if block_given?
    end

      # The heading of the column. This should be an instance of
      # PDF::SimpleTable::Column::Heading. If it is not, it will be
      # converted into one.
    attr_accessor :heading
    def heading=(hh) #:nodoc:
      unless hh.kind_of?(Heading)
        hh = Heading.new(hh)
      end
      @heading = hh
    end
      # The name of the column.
    attr_reader   :name
      # The width of the column. If this value is set, the column will be
      # exactly this number of units wide.
    attr_accessor :width
      # The data name that will be used to provide a hyperlink for values in
      # this column.
    attr_accessor :link_name
      # The justification of the column. May be :left, :right, :center, or
      # :full.
    attr_accessor :justification

      # Formatting options for heading rows. Each column can have a separate
      # heading value.
    class Heading
      def initialize(title = nil)
        @title = title
        yield self if block_given?
      end

        # Indicates that the heading should be rendered bold.
      attr_accessor :bold
        # The justification of the heading of the column. May be :left,
        # :center, :right, or :full.
      attr_accessor :justification
        # The title of the heading. If nothing is present, the name of the
        # column will be used when headings are displayed.
      attr_accessor :title
    end
  end

  def initialize
    @column_order = []
    @data         = []
    @columns      = {}

    @show_lines           = :outer
    @show_headings        = true
    @shade_rows           = :shaded
    @shade_color          = Color::RGB::Grey80
    @shade_color2         = Color::RGB::Grey70
    @shade_headings       = false
    @shade_heading_color  = Color::RGB::Grey90
    @font_size            = 10
    @heading_font_size    = 12
    @title_font_size      = 12
    @title_gap            = 5
    @title_color          = Color::RGB::Black
    @heading_color        = Color::RGB::Black
    @text_color           = Color::RGB::Black
    @line_color           = Color::RGB::Black
    @position             = :center
    @orientation          = :center
    @bold_headings        = false

    @cols                 = PDF::Writer::OHash.new
    @width                = 0
    @maximum_width        = 0

    @gap                  = 5
    @row_gap              = 2
    @column_gap           = 5
    @header_gap           = 0

    @minimum_space        = 0
    @protect_rows         = 1
    @split_rows           = false

    @inner_line_style     = PDF::Writer::StrokeStyle.new(1)
    @outer_line_style     = PDF::Writer::StrokeStyle.new(1)

    yield self if block_given?
  end

    # An array of Hash entries. Each row is a Hash where the keys are the
    # names of the columns as specified in #column_order and the values are
    # the values of the cell.
  attr_accessor :data
    # An array that defines the order of the columns in the table. The
    # values in this array are the column names in #data. The columns will
    # be presented in the order defined here.
  attr_accessor :column_order
    # An array that defines columns and column options for the table. The
    # entries should be PDF::SimpleTable::Column objects.
  attr_accessor :columns

    # The title to be put on the top of the table.
  attr_accessor :title

    # Whether to display the lines on the table or not. Valid values are:
    #
    # <tt>:none</tt>::    Displays no lines.
    # <tt>:outer</tt>::   Displays outer lines only. *Default*
    # <tt>:inner</tt>::   Displays inner lines only.
    # <tt>:all</tt>::     Displays all lines, inner and outer.
  attr_accessor :show_lines
    # Displays the headings for the table if +true+. The default is +true+.
  attr_accessor :show_headings
    # Controls row shading.
    #
    # <tt>:none</tt>::    No row shading; all rows are the standard
    #                     background colour.
    # <tt>:shaded</tt>::  Alternate lines will be shaded; half of the rows
    #                     will be the standard background colour; the rest
    #                     of the rows will be shaded with #shade_color.
    #                     *Default*
    # <tt>:striped</tt>:: Alternate lines will be shaded; half of the rows
    #                     will be shaded with #shade_color; the rest of the
    #                     rows will be shaded with #shade_color2.
  attr_accessor :shade_rows
    # The main row shading colour. Defaults to Color::RGB::Grey80. Used with
    # #shade_rows of <tt>:shaded</tt> and <tt>:striped</tt>.
  attr_accessor :shade_color
    # The alternate row shading colour, used with #shade_rows of
    # <tt>:striped</tt>. Defaults to Color::RGB::Grey70.
  attr_accessor :shade_color2
    # Places a background colour in the heading if +true+.
  attr_accessor :shade_headings
    # Defines the colour of the background shading for the heading if
    # #shade_headings is +true+. Default is Color::RGB::Grey90.
  attr_accessor :shade_heading_color
    # The font size of the data cells, in points. Defaults to 10 points.
  attr_accessor :font_size
    # The font size of the heading cells, in points. Defaults to 12 points.
  attr_accessor :heading_font_size
    # The font size of the title, in points. Defaults to 12 points.
  attr_accessor :title_font_size
    # The gap, in PDF units, between the title and the table. Defaults to 5
    # units.
  attr_accessor :title_gap
    # The text colour of the title. Defaults to Color::RGB::Black.
  attr_accessor :title_color
    # The text colour of the heading. Defaults to Color::RGB::Black.
  attr_accessor :heading_color
    # The text colour of the body cells. Defaults to Color::RGB::Black.
  attr_accessor :text_color
    # The colour of the table lines. Defaults to Color::RGB::Black.
  attr_accessor :line_color
    # The +x+ position of the table. This will be one of:
    #
    # <tt>:left</tt>::    Aligned with the left margin.
    # <tt>:right</tt>::   Aligned with the right margin.
    # <tt>:center</tt>::  Centered between the margins. *Default*.
    # <em>offset</em>::   The absolute position of the table, relative from
    #                     the left margin.
  attr_accessor :position
    # The orientation of the table relative to #position.
    #
    # <tt>:left</tt>::    The table is to the left of #position.
    # <tt>:right</tt>::   The table is to the right of #position.
    # <tt>:center</tt>::  The table is centred at #position.
    # <em>offset</em>::   The left of the table is offset from #position.
  attr_accessor :orientation
    # Makes the heading text bold if +true+. Defaults to +false+.
  attr_accessor :bold_headings
    # Specifies the width of the table. If the table is smaller than the
    # provided width, columns are proportionally stretched to fit the width
    # of the table. If the table is wider than the provided width, columns
    # are proportionally shrunk to fit the width of the table. Content may
    # need to wrap in this case.
    #
    # Defaults to zero, which indicates that the size whould be determined
    # automatically based on the content and the margins.
  attr_accessor :width
    # Specifies the maximum width of the table. The table will not grow
    # larger than this width under any circumstances.
    #
    # Defaults to zero, which indicates that there is no maximum width
    # (aside from the margin size).
  attr_accessor :maximum_width
    # The space, in PDF user units, added to the top and bottom of each row
    # between the text and the lines of the cell. Default 2 units.
  attr_accessor :row_gap
    # The space, in PDF user units, on the left and right sides of each
    # cell. Default 5 units.
  attr_accessor :column_gap

    # The minimum space between the bottom of each row and the bottom
    # margin. If the amount of space is less than this, a new page will be
    # started. Default is 100 PDF user units.
  attr_accessor :minimum_space
    # The number of rows to hold with the heading on the page. If there are
    # less than this number of rows on the page, then move the whole lot
    # onto the next page. Default is one row.
  attr_accessor :protect_rows
    # Allows a table's rows to be split across page boundaries if +true+.
    # This defaults to +false+.
  attr_accessor :split_rows
    # The number of PDF user units to leave open at the top of a page after
    # a page break. This is typically used for a repeating page header, etc.
    # Defaults to zero units.
  attr_accessor :header_gap
    # Defines the inner line style. The default style is a solid line with a
    # thickness of 1 unit.
  attr_accessor :inner_line_style
    # Defines the outer line style. The default style is a solid line with a
    # thickness of 1 unit.
  attr_accessor :outer_line_style

    # Render the table on the PDF::Writer document provided.
  def render_on(pdf)
    if @column_order.empty?
      raise TypeError, PDF::Writer::Lang[:simpletable_columns_undefined]
    end
    if @data.empty?
      raise TypeError, PDF::Writer::Lang[:simpletable_data_empty]
    end

    low_y = descender = y0 = y1 = y = nil

    @cols = PDF::Writer::OHash.new
    @column_order.each do |name|
      col = @columns[name]
      if col
        @cols[name] = col
      else
        @cols[name] = PDF::SimpleTable::Column.new(name)
      end
    end

    @gap = 2 * @column_gap

    max_width = __find_table_max_width__(pdf)
    pos, t, x, adjustment_width, set_width = __find_table_positions__(pdf, max_width)

    # if max_width is specified, and the table is too wide, and the width
    # has not been set, then set the width.
    if @width.zero? and @maximum_width.nonzero? and ((t - x) > @maximum_width)
      @width = @maximum_width
    end

    if @width and (adjustment_width > 0) and (set_width < @width)
        # First find the current widths of the columns involved in this
        # mystery
      cols0 = PDF::Writer::OHash.new
      cols1 = PDF::Writer::OHash.new

      xq = presentWidth = 0
      last = nil

      pos.each do |name, colpos|
        if @cols[last].nil? or
          @cols[last].width.nil? or
          @cols[last].width <= 0
          unless last.nil? or last.empty?
            cols0[last] = colpos - xq - @gap
            presentWidth += (colpos - xq - @gap)
          end
        else
          cols1[last] = colpos - xq
        end
        last = name
        xq = colpos
      end

      # cols0 contains the widths of all the columns which are not set
      needed_width = @width - set_width

        # If needed width is negative then add it equally to each column,
        # else get more tricky.
      if presentWidth < needed_width
        diff = (needed_width - presentWidth) / cols0.size.to_f
        cols0.each_key { |name| cols0[name] += diff }
      else
        cnt = 0
        loop do
          break if (presentWidth <= needed_width) or (cnt >= 100)
          cnt += 1 # insurance policy
            # Find the widest columns and the next to widest width
          aWidest = []
          nWidest = widest = 0
          cols0.each do |name, w|
            if w > widest
              aWidest = [ name ]
              nWidest = widest
              widest = w
            elsif w == widest
              aWidest << name
            end
          end

          # Then figure out what the width of the widest columns would
          # have to be to take up all the slack.
          newWidestWidth = widest - (presentWidth - needed_width) / aWidest.size.to_f
          if newWidestWidth > nWidest
            aWidest.each { |name| cols0[name] = newWidestWidth }
            presentWidth = needed_width
          else
            # There is no space, reduce the size of the widest ones down
            # to the next size down, and we will go round again
            aWidest.each { |name| cols0[name] = nWidest }
            presentWidth -= (widest - nWidest) * aWidest.size
          end
        end
      end

        # cols0 now contains the new widths of the constrained columns. now
        # need to update the pos and max_width arrays
      xq = 0
      pos.each do |name, colpos|
        pos[name] = xq

        if @cols[name].nil? or
          @cols[name].width.nil? or
          @cols[name].width <= 0
          if not cols0[name].nil?
            xq += cols0[name] + @gap
            max_width[name] = cols0[name]
          end
        else
          xq += cols1[name] unless cols1[name].nil?
        end
      end

      t = x + @width
      pos[:__last_column__] = t
    end

    # now adjust the table to the correct location across the page
    case @position
    when :left
      xref = pdf.absolute_left_margin
    when :right
      xref = pdf.absolute_right_margin
    when :center
      xref = pdf.margin_x_middle
    else
      xref = @position
    end

    case @orientation
    when :left
      dx = xref - t
    when :right
      dx = xref
    when :center
      dx = xref - (t / 2.0)
    else
      dx = xref + @orientation
    end

    pos.each { |k, v| pos[k] = v + dx }

    base_x0 = x0 = x + dx
    base_x1 = x1 = t + dx

    base_left_margin = pdf.absolute_left_margin
    base_pos = pos.dup

      # Ok, just about ready to make me a table.
    pdf.fill_color @text_color
    pdf.stroke_color @shade_color 

    middle = (x0 + x1) / 2.0

      # Start a transaction. This transaction will be used to regress the
      # table if there are not enough rows protected. 
    tg = Transaction::Simple::Group.new(pdf, self)
    tg.start_transaction(:table)
    moved_once = false if @protect_rows.nonzero?

    abortTable = true
    loop do # while abortTable
      break unless abortTable
      abortTable = false

      dm = pdf.absolute_left_margin - base_left_margin
      base_pos.each { |k, v| pos[k] = v + dm }
      x0 = base_x0 + dm
      x1 = base_x1 + dm
      middle = (x0 + x1) / 2.0

        # If the title is set, then render it.
      unless @title.nil? or @title.empty?
        w = pdf.text_width(@title, @title_font_size)
        _y = pdf.y - pdf.font_height(@title_font_size)
        if _y < pdf.absolute_bottom_margin
          pdf.start_new_page

            # margins may have changed on the new page
          dm = pdf.absolute_left_margin - base_left_margin
          base_pos.each { |k, v| pos[k] = v + dm }
          x0 = base_x0 + dm
          x1 = base_x1 + dm
          middle = (x0 + x1) / 2.0
        end

        pdf.y -= pdf.font_height(@title_font_size)
        pdf.fill_color @title_color
        pdf.add_text(middle - w / 2.0, pdf.y, title, @title_font_size)
        pdf.y -= @title_gap
      end

        # Margins may have changed on the new_page.
      dm = pdf.absolute_left_margin - base_left_margin
      base_pos.each { |k, v| pos[k] = v + dm }
      x0 = base_x0 + dm
      x1 = base_x1 + dm
      middle = (x0 + x1) / 2.0

      y = pdf.y  # simplifies the code a bit
      low_y = y if low_y.nil? or y < low_y 

        # Make the table
      height = pdf.font_height @font_size
      descender = pdf.font_descender @font_size

      y0 = y + descender
      dy = 0

      if @show_headings
        # This function will move the start of the table to a new page if
        # it does not fit on this one.
        hOID = __open_new_object__(pdf) if @shade_headings
        pdf.fill_color @heading_color
        _height, y = __table_column_headings__(pdf, pos, max_width, height,
          descender, @row_gap, @heading_font_size, y)
        pdf.fill_color @text_color
        y0 = y + _height
        y1 = y

        if @shade_headings
          pdf.close_object
          pdf.fill_color! @shade_heading_color
          pdf.rectangle(x0 - @gap / 2.0, y, x1 - x0, _height).fill
          pdf.reopen_object(hOID)
          pdf.close_object
          pdf.restore_state
        end

          # Margins may have changed on the new_page
        dm = pdf.absolute_left_margin - base_left_margin
        base_pos.each { |k, v| pos[k] = v + dm }
        x0 = base_x0 + dm
        x1 = base_x1 + dm
        middle = (x0 + x1) / 2.0
      else
        y1 = y0
      end

      first_line = true

      # open an object here so that the text can be put in over the
      # shading
      tOID = __open_new_object__(pdf) unless :none == @shade_rows

      cnt = 0
      cnt = 1 unless @shade_headings
      newPage = false
      @data.each do |row|
        cnt += 1
          # Start a transaction that will be used for this row to prevent it
          # from being split.
        unless @split_rows
          pageStart = pdf.pageset.size

          columnStart = pdf.column_number if pdf.columns?

          tg.start_transaction(:row)
          row_orig = row
          y_orig = y
          y0_orig = y0
          y1_orig = y1
        end # unless @split_rows

        ok = false
        second_turn = false
        loop do # while !abortTable and !ok
          break if abortTable or ok

          mx = 0
          newRow = true

          loop do # while !abortTable and (newPage or newRow)
            break if abortTable or not (newPage or newRow)

            y -= height
            low_y = y if low_y.nil? or y < low_y 

            if newPage or y < (pdf.absolute_bottom_margin + @minimum_space)
                # check that enough rows are with the heading
              moved_once = abortTable = true if @protect_rows.nonzero? and not moved_once and cnt <= @protect_rows

              y2 = y - mx + (2 * height) + descender - (newRow ? 1 : 0) * height

              unless :none == @show_lines
                y0 = y1 unless @show_headings

                __table_draw_lines__(pdf, pos, @gap, x0, x1, y0, y1, y2,
                  @line_color, @inner_line_style, @outer_line_style,
                  @show_lines)
              end

              unless :none == @shade_rows
                pdf.close_object
                pdf.restore_state
              end

              pdf.start_new_page
              pdf.save_state

                # and the margins may have changed, this is due to the
                # possibility of the columns being turned on as the columns are
                # managed by manipulating the margins
              dm = pdf.absolute_left_margin - base_left_margin
              base_pos.each { |k, v| pos[k] = v + dm }
              x0 = base_x0 + dm
              x1 = base_x1 + dm

              tOID = __open_new_object__(pdf) unless :none == @shade_rows

              pdf.fill_color! @text_color

              y = pdf.absolute_top_margin - @header_gap
              low_y = y
              y0 = y + descender
              mx = 0

              if @show_headings
                hOID = __open_new_object__(pdf) if @shade_headings

                pdf.fill_color @heading_color
                _height, y = __table_column_headings__(pdf, pos, max_width,
                  height, descender, @row_gap, @heading_font_size, y)
                pdf.fill_color @text_color

                y0 = y + _height
                y1 = y

                if @shade_headings
                  pdf.close_object
                  pdf.fill_color! @shade_heading_color
                  pdf.rectangle(x0 - @gap / 2, y, x1 - x0, _height).fill
                  pdf.reopen_object(hOID)
                  pdf.close_object
                  pdf.restore_state
                end

                dm = pdf.absolute_left_margin - base_left_margin
                base_pos.each { |k, v| pos[k] = v + dm }
                x0 = base_x0 + dm
                x1 = base_x1 + dm
                middle = (x0 + x1) / 2.0
              else
                y1 = y0
              end

              first_line = true
              y -= height
              low_y = y if low_y.nil? or y < low_y 
            end

            newRow = false

              # Write the actual data. If these cells need to be split over
              # a page, then newPage will be set, and the remaining text
              # will be placed in leftOvers
            newPage = false
            leftOvers = PDF::Writer::OHash.new

            @cols.each do |name, column|
              pdf.pointer = y + height
              colNewPage = false

              unless row[name].nil?
                lines = row[name].to_s.split(/\n/)
                if column and column.link_name
                  lines.map! do |kk|
                    link = row[column.link_name]
                    if link
                      "<c:alink uri='#{link}'>#{kk}</c:alink>"
                    else
                      kk
                    end
                  end
                end
              else
                lines = []
              end

              pdf.y -= @row_gap

              lines.each do |line|
                pdf.send(:preprocess_text, line)
                start = true

                loop do
                  break if (line.nil? or line.empty?) and not start
                  start = false

                  _y = pdf.y - height if not colNewPage

                    # a new page is required
                  newPage = colNewPage = true if _y < pdf.absolute_bottom_margin

                  if colNewPage
                    if leftOvers[name].nil?
                      leftOvers[name] = [line]
                    else
                      leftOvers[name] << "\n#{line}"
                    end
                    line = nil
                  else
                    if column and column.justification
                      just = column.justification
                    end
                    just ||= :left

                    pdf.y = _y
                    line = pdf.add_text_wrap(pos[name], pdf.y,
                                             max_width[name], line,
                                             @font_size, just)
                  end
                end
              end

              dy = y + height - pdf.y + @row_gap
              mx = dy - height * (newPage ? 1 : 0) if (dy - height * (newPage ? 1 : 0)) > mx
            end

              # Set row to leftOvers so that they will be processed onto the
              # new page
            row = leftOvers

            # Now add the shading underneath
            unless :none == @shade_rows
              pdf.close_object

              if (cnt % 2).zero?
                pdf.fill_color!(@shade_color)
                pdf.rectangle(x0 - @gap / 2.0, y + descender + height - mx, x1 - x0, mx).fill
              elsif (cnt % 2).nonzero? and :striped == @shade_rows
                pdf.fill_color!(@shade_color2)
                pdf.rectangle(x0 - @gap / 2.0, y + descender + height - mx, x1 - x0, mx).fill
              end
              pdf.reopen_object(tOID)
            end

            if :inner == @show_lines or :all == @show_lines
              # draw a line on the top of the block
              pdf.save_state
              pdf.stroke_color! @line_color
              if first_line
                pdf.stroke_style @outer_line_style
                first_line = false
              else
                pdf.stroke_style @inner_line_style
              end
              pdf.line(x0 - @gap / 2.0, y + descender + height, x1 - @gap / 2.0, y + descender + height).stroke
              pdf.restore_state
            end
          end

          y = y - mx + height
          pdf.y = y
          low_y = y if low_y.nil? or y < low_y 

            # checking row split over pages
          unless @split_rows
            if (((pdf.pageset.size != pageStart) or (pdf.columns? and columnStart != pdf.column_number)) and not second_turn)
              # then we need to go back and try that again!
              newPage = second_turn = true
              tg.rewind_transaction(:row)
              row = row_orig
              low_y = y = y_orig
              y0 = y0_orig
              y1 = y1_orig
              ok = false

              dm = pdf.absolute_left_margin - base_left_margin
              base_pos.each { |k, v| pos[k] = v + dm }
              x0 = base_x0 + dm
              x1 = base_x1 + dm
            else
              tg.commit_transaction(:row)
              ok = true
            end
          else
            ok = true # don't go 'round the loop if splitting rows is allowed
          end
        end

        if abortTable
            # abort_transaction if not ok only the outer transaction should
            # be operational.
          tg.rewind_transaction(:table)
          pdf.start_new_page
            # fix a bug where a moved table will take up the whole page.
          low_y = nil
          pdf.save_state
          break
        end
      end
    end

    if low_y <= y
      y2 = low_y + descender
    else
      y2 = y + descender
    end

    unless :none == @show_lines
      y0 = y1 unless @show_headings

      __table_draw_lines__(pdf, pos, @gap, x0, x1, y0, y1, y2, @line_color,
        @inner_line_style, @outer_line_style, @show_lines)
    end

    # close the object for drawing the text on top
    unless :none == @shade_rows
      pdf.close_object
      pdf.restore_state
    end

    pdf.y = low_y

      # Table has been put on the page, the rows guarded as required; commit.
    tg.commit_transaction(:table)

    y
  rescue Exception => ex
    begin
      tg.abort_transaction(:table) if tg.transaction_open?
    rescue
      nil
    end
    raise ex
  end

  WIDTH_FACTOR = 1.01

    # Find the maximum widths of the text within each column. Default to
    # zero.
  def __find_table_max_width__(pdf)
    max_width = PDF::Writer::OHash.new(0)

      # Find the maximum cell widths based on the data and the headings.
      # Passing through the data multiple times is unavoidable as we must do
      # some analysis first.
    @data.each do |row|
      @cols.each do |name, column|
        w = pdf.text_width(row[name].to_s, @font_size)
        w *= WIDTH_FACTOR

        max_width[name] = w if w > max_width[name]
      end
    end

    @cols.each do |name, column|
      title = column.heading.title if column.heading
      title ||= column.name
      w = pdf.text_width(title, @heading_font_size)
      w *= WIDTH_FACTOR
      max_width[name] = w if w > max_width[name]
    end
    max_width
  end
  private :__find_table_max_width__

    # Calculate the start positions of each of the columns. This is based
    # on max_width, but may be modified with column options.
  def __find_table_positions__(pdf, max_width)
    pos = PDF::Writer::OHash.new
    x = t = adjustment_width = set_width = 0

    max_width.each do |name, w|
      pos[name] = t
        # If the column width has been specified then set that here, also
        # total the width avaliable for adjustment.
      if not @cols[name].nil? and
         not @cols[name].width.nil? and
         @cols[name].width > 0
        t += @cols[name].width
        max_width[name] = @cols[name].width - @gap
        set_width += @cols[name].width
      else
        t += w + @gap
        adjustment_width += w
        set_width += @gap
      end
    end
    pos[:__last_column__] = t

    [pos, t, x, adjustment_width, set_width]
  end
  private :__find_table_positions__

      # Uses ezText to add the text, and returns the height taken by the
      # largest heading. This page will move the headings to a new page if
      # they will not fit completely on this one transaction support will be
      # used to implement this.
  def __table_column_headings__(pdf, pos, max_width, height, descender, gap, size, y)
    mx = second_go = 0
    start_page = pdf.pageset.size

      # y is the position at which the top of the table should start, so the
      # base of the first text, is y-height-gap-descender, but ezText starts
      # by dropping height.

      # The return from this function is the total cell height, including
      # gaps, and y is adjusted to be the postion of the bottom line.
    tg = Transaction::Simple::Group.new(pdf, self)
    tg.start_transaction(:column_headings)

    ok = false
    y -= gap
    loop do
      break if ok
      @cols.each do |name, column|
        pdf.pointer = y

        if column.heading
          justification = column.heading.justification
          bold          = column.heading.bold
          title         = column.heading.title
        end

        justification ||= :left
        bold ||= @bold_headings
        title ||= column.name

        title = "<b>#{title}</b>" if bold

        pdf.text(title, :font_size => size, :absolute_left => pos[name],
                :absolute_right => (max_width[name] + pos[name]),
                :justification => justification)
        dy = y - pdf.y
        mx = dy if dy > mx
      end

      y -= (mx + gap) - descender # y = y - mx - gap + descender

        # If this has been moved to a new page, then abort the transaction;
        # move to a new page, and put it there. Do not check on the second
        # time around to avoid an infinite loop.
      if (pdf.pageset.size != start_page and not second_go)
        tg.rewind_transaction(:column_headings)

        pdf.start_new_page
        save_state
        y = @y - gap - descender
        ok = false
        second_go = true
        mx = 0
      else
        tg.commit_transaction(:column_headings)
        ok = true
      end
    end

    return [mx + gap * 2 - descender, y]
  rescue Exception => ex
    begin
      tg.abort_transaction(:column_headings) if tg.transaction_open?(:column_headings)
    rescue
      nil
    end
    raise ex
  end
  private :__table_column_headings__

  def __table_draw_lines__(pdf, pos, gap, x0, x1, y0, y1, y2, col, inner, outer, opt = :outer)
    x0 = 1000
    x1 = 0

    pdf.stroke_color(col)

    cnt = 0
    n = pos.size

    pos.each do |name, x|
      cnt += 1

      if (cnt == 1 or cnt == n)
        pdf.stroke_style outer
      else
        pdf.stroke_style inner
      end

      pdf.line(x - gap / 2.0, y0, x - gap / 2.0, y2).stroke
      x1 = x if x > x1
      x0 = x if x < x0
    end

    pdf.stroke_style outer

    pdf.line(x0 - (gap / 2.0) - (outer.width / 2.0), y0,
             x1 - (gap / 2.0) + (outer.width / 2.0), y0).stroke

      # Only do the second line if it is different than the first AND each
      # row does not have a line on it.
    if y0 != y1 and @show_lines == :outer
      pdf.line(x0 - gap / 2.0, y1, x1 - gap / 2.0, y1).stroke
    end
    pdf.line(x0 - (gap / 2.0) - (outer.width / 2.0), y2,
             x1 - (gap / 2.0) + (outer.width / 2.0), y2).stroke
  end
  private :__table_draw_lines__

  def __open_new_object__(pdf)
    pdf.save_state
    tOID = pdf.open_object
    pdf.close_object
    pdf.add_object(tOID)
    pdf.reopen_object(tOID)
    tOID
  end
  private :__open_new_object__
end
