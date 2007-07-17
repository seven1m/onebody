#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: stddev.rb,v 1.9.2.2 2005/09/07 17:01:14 austin Exp $
#++
require 'pdf/writer'
require 'pdf/charts'
require 'ostruct'

  # Creates a standard deviation chart. This is a type of chart that is
  # effective for the display of survey results or other data that can
  # easily be measured in terms of the average and the standard deviation
  # from that average.
  #
  # The scale of responses is the vertical scale; the average data points
  # and standard deviation values are the horizontal scale.
class PDF::Charts::StdDev
  VERSION = '1.1.3'

    # A data element.
  DataPoint = Struct.new(:label, :average, :stddev)

    # A label for displaying the scale (vertical) of data in the dataset or
    # the data set identifiers.
  class Label
    def initialize
      yield self if block_given?
    end

      # The height of the label, in PDF user units. Ignored for scale
      # labels.
    attr_accessor :height
      # The background color of the label. Ignored for scale labels.
    attr_accessor :background_color
      # The text color of the label.
    attr_accessor :text_color
      # The text size, in points, of the label.
    attr_accessor :text_size
      # The padding of the label. Only used for scale labels.
    attr_accessor :pad
      # The decimal precision of the label. Only used for scale labels.
    attr_accessor :decimal_precision
  end

    # The scale of the dataset.
  class Scale
    def initialize(args = { })
      @range        = args[:range]
      @step         = args[:step]
      @style        = args[:style]
      @show_labels  = false

      yield self if block_given?

      raise TypeError, PDF::Lange[:charts_stddev_scale_norange] if @range.nil?
      raise TypeError, PDF::Lange[:charts_stddev_scale_nostep] if @step.nil?
    end

      # Range of the scale. This should be a Range object.
    attr_accessor :range
      # The lower end of the range of the scale. The scale range may be
      # modified by changing this value.
    attr_accessor :first
    def first #:nodoc:
      @range.first
    end
    def first=(ff) #:nodoc:
      @range = (ff..@range.last)
    end
      # The upper end of the range of the scale. The scale range may be
      # modified by changing this value.
    attr_accessor :last
    def last #:nodoc:
      @range.last
    end
    def last=(ll) #:nodoc:
      @range = (@range.first..ll)
    end
      # Defines the step of the scale. Each step represents a vertical
      # position on the chart.
    attr_accessor :step
      # Defines the line style for the scale on the chart. If this is unset
      # (+nil+), there will be no horizontal marks across the chart for the
      # steps of the scale.
    attr_accessor :style
      # Shows the scale labels if +true+.
    attr_accessor :show_labels
      # Defines the label options.
    attr_accessor :label
  end

    # This is any line that will be drawn; this is a combination of the line
    # style (which must be a PDF::Writer::StrokeStyle object) and a color.
  class Marker
    def initialize
      yield self if block_given?
    end

      # The stroke style of the marker.
    attr_accessor :style
      # The stroke color of the marker.
    attr_accessor :color
  end

  def initialize
    @data                       = []

    @scale                      = Scale.new do |scale|
      scale.range               = 0..6
      scale.step                = 1
      scale.style               = PDF::Writer::StrokeStyle.new(0.25)
      scale.show_labels         = false
      scale.label               = Label.new do |label|
        label.text_size         = 8
        label.text_color        = Color::RGB::Black
        label.pad               = 2
        label.decimal_precision = 1
      end
    end
    @leading_gap              = 10
    @show_labels              = true
    @label                    = Label.new do |label|
      label.height            = 25
      label.background_color  = Color::RGB::Black
      label.text_color        = Color::RGB::White
      label.text_size         = 12
    end

    @outer_borders            = Marker.new do |marker|
      marker.style            = PDF::Writer::StrokeStyle.new(1.5)
      marker.color            = Color::RGB::Black
    end
    @inner_borders            = nil

    @dot                      = Marker.new do |marker|
      marker.style            = PDF::Writer::StrokeStyle.new(5)
      marker.color            = Color::RGB::Black
    end
    @bar                      = Marker.new do |marker|
      marker.style            = PDF::Writer::StrokeStyle.new(0.5)
      marker.color            = Color::RGB::Black
    end
    @upper_crossbar           = Marker.new do |marker|
      marker.style            = PDF::Writer::StrokeStyle.new(1)
      marker.color            = Color::RGB::Black
    end
    @lower_crossbar           = Marker.new do |marker|
      marker.style            = PDF::Writer::StrokeStyle.new(1)
      marker.color            = Color::RGB::Black
    end

    @height                   = 200
    @maximum_width            = 500
    @datapoint_width          = 35

    yield self if block_given?
  end

    # The data used to generate the standard deviation chart. This is an
    # array of DataPoint objects, each containing a +label+, an +average+,
    # and the +stddev+ (standard deviation) from that average.
  attr_reader :data
    # The scale of the chart. All values must be within this range. This
    # will be a Scale object. It defaults to a scale of 0..6 with a step of
    # 1.
  attr_accessor :scale

    # The minimum gap between the chart and the bottom of the page, in
    # PDF user units.
  attr_accessor :leading_gap

    # This will be +true+ if labels are to be displayed.
  attr_accessor :show_labels
    # The label style of the labels if they are displayed. This must be a
    # PDF::Charts::StdDev::Label object.
  attr_accessor :label

    # The inner border style. If +nil+, no inner borders are drawn. This is
    # a PDF::Charts::StdDev::Marker object.
  attr_accessor :inner_borders
    # The outer border style. If +nil+, no inner borders are drawn. This is
    # a PDF::Charts::StdDev::Marker object.
  attr_accessor :outer_borders

    # The dot marker. A filled circle will be drawn with this information.
    # If +nil+, the dot will not be drawn. This is a
    # PDF::Charts::StdDev::Marker object.
  attr_accessor :dot
    # The standard deviation bar. A line will be drawn through the dot
    # marker (if drawn) from the upper to lower standard deviation.
    # If +nil+, the line will not be drawn. This is a
    # PDF::Charts::StdDev::Marker object.
  attr_accessor :bar
    # The upper crossbar. A line will be drawn across the top of the
    # standard deviation bar to the width of the dot marker. If #dot is
    # +nil+, then the line will be twice as wide as it is thick. If +nil+,
    # the upper crossbar will not be drawn. This is a
    # PDF::Charts::StdDev::Marker object.
  attr_accessor :upper_crossbar
    # The lower crossbar. A line will be drawn across the bottom of the
    # standard deviation bar to the width of the dot marker. If #dot is
    # +nil+, then the line will be twice as wide as it is thick. If +nil+,
    # the lower crossbar will not be drawn. This is a
    # PDF::Charts::StdDev::Marker object.
  attr_accessor :lower_crossbar

    # The height of the chart in PDF user units. Default 200 units.
  attr_accessor :height
    # The maximum width of the chart in PDF user units. Default 500 units.
  attr_accessor :maximum_width
    # The width of a single datapoint.
  attr_accessor :datapoint_width

    # Draw the standard deviation chart on the supplied PDF document.
  def render_on(pdf)
    raise TypeError, PDF::Writer::Lang[:charts_stddev_data_empty] if @data.empty?
    data = @data.dup
    leftover_data = nil

    loop do
      # Set up the scale information.
      scale = []

      (@scale.first + @scale.step).step(@scale.last, @scale.step) do |ii|
        scale << "%01.#{@scale.label.decimal_precision}f" % ii
      end

      scales = PDF::Writer::OHash.new
      scale.each_with_index do |gg, ii|
        scales[ii] = OpenStruct.new
        scales[ii].value = gg
      end

      # Add information about the scales' locations to the scales
      # hash. Note that the count is one smaller than it should be, so we're
      # increasing it. The first scale is the bottom of the chart.
      scale_count = scale.size + 1

      label_height_adjuster = 0
      label_height_adjuster = @label.height if @show_labels

      chart_area_height = @height - label_height_adjuster
      scale_height   = chart_area_height / scale_count.to_f

      scales.each_key do |index|
        this_height = scale_height * (index + 1) + @label.height
        scales[index].line_height = this_height
        if @scale.show_labels
          scales[index].label_height = this_height -
          (@scale.label.text_size / 3.0)
        end
      end

      # How many sections do we need in this chart, and how wide will it
      # need to be?
      chunk_width = @datapoint_width
      num_chunks  = data.size
      widest_scale_label = 0

      if @scale.show_labels
        scales.each_value do |scale|
          this_width = pdf.text_width(scale.value, @scale.label.text_size)
          widest_scale_label = this_width if this_width > widest_scale_label
        end
      end

      chart_width = chunk_width * num_chunks
      total_width = chart_width + widest_scale_label + @scale.label.pad

        # What happens if the projected width of the chart is too big?
        # Figure out how to break the chart in pieces.
      if total_width > @maximum_width
        max_column_count = 0
        base_width = widest_scale_label + @scale.label.pad
        (1..(num_chunks + 1)).each do |ii|
          if (base_width + (ii * chunk_width)) > @maximum_width
            break
          else
            max_column_count += 1
          end
        end

        leftover_data = data.slice!(max_column_count, -1)

        num_chunks  = data.size
        chart_width = chunk_width * num_chunks
        total_width = chart_width + widest_scale_label + @scale.label.pad
      end

      chart_y = pdf.y - @height + @leading_gap
      chart_y += (@outer_borders.style.width * 2.0) if @outer_borders

      if chart_y < pdf.bottom_margin
        pdf.start_new_page
        chart_y = pdf.y - @height
        chart_y += (@outer_borders.style.width * 2.0) if @outer_borders
      end

      chart_x = pdf.absolute_x_middle - (total_width / 2.0) + widest_scale_label

        # Add labels, if needed.
      if @show_labels
        pdf.save_state
        pdf.fill_color! @label.background_color
        # Draw a rectangle for each label
        num_chunks.times do |ii|
          this_x = chart_x + ii * chunk_width
          pdf.rectangle(this_x, chart_y, chunk_width, @label.height).fill
        end

          # Add a border above the label rectangle.
        if @outer_borders
          pdf.stroke_style! @outer_borders.style
          pdf.line(chart_x, chart_y + @label.height, chart_x + chart_width, chart_y + @label.height).stroke
        end
        pdf.fill_color! @label.text_color

        data.each_with_index do |datum, ii|
          label = datum.label.to_s
          label_width = pdf.text_width(label, @label.text_size)
          this_x = chart_x + (ii * chunk_width) + (chunk_width / 2.0) - (label_width / 2.0)
          this_y = chart_y + (@label.height / 2.0) - (@label.text_size / 3.0)
          pdf.add_text(this_x, this_y, label, @label.text_size)
        end
        pdf.restore_state
      end

      if @inner_borders
        pdf.save_state
        pdf.stroke_color! @inner_borders.color
        pdf.stroke_style! @inner_borders.style
        (num_chunks - 1).times do |ii|
          this_x = chart_x + (ii * chunk_width) + chunk_width
          pdf.line(this_x, chart_y, this_x, chart_y + @height).stroke
        end
        pdf.restore_state
      end

      pdf.save_state
      if @outer_borders
        pdf.stroke_color! @outer_borders.color
        pdf.stroke_style! @outer_borders.style
        pdf.rectangle(chart_x, chart_y, chart_width, @height).stroke
      end

      if @scale.style
        pdf.save_state
        pdf.stroke_style! @scale.style
        scales.each_value do |scale|
          this_y = chart_y + scale.line_height
          pdf.line(chart_x, this_y, chart_x + chart_width, this_y).stroke
        end
        pdf.restore_state
      end

      if @scale.show_labels
        pdf.save_state
        scales.each_value do |scale|
          this_y = chart_y + scale.label_height
          label_width = pdf.text_width(scale.value, @scale.label.text_size)
          this_x = chart_x - label_width - @scale.label.pad
          pdf.fill_color! @scale.label.text_color
          pdf.add_text(this_x, this_y, scale.value, @scale.label.text_size)
        end
        pdf.restore_state
      end

      data.each_with_index do |datum, ii|
        avg_height    = datum.average * scale_height
        stddev_height = datum.stddev * scale_height
        this_y        = chart_y + label_height_adjuster + avg_height
        this_x        = chart_x + (ii * chunk_width) + (chunk_width / 2.0)
        line_top_y    = this_y + (stddev_height / 2.0)
        line_bot_y    = this_y - (stddev_height / 2.0)

          # Plot the dot
        if @dot
          pdf.stroke_color! @dot.color
          pdf.stroke_style! @dot.style
          pdf.circle_at(this_x, this_y, (@dot.style.width / 2.0)).fill
        end

          # Plot the bar
        if @bar
          pdf.stroke_color! @bar.color
          pdf.stroke_style! @bar.style
          pdf.line(this_x, line_top_y, this_x, line_bot_y).stroke
        end

          # Plot the crossbars
        if @upper_crossbar
          if @dot
            cb_width = @dot.style.width
          else
            cb_width = @upper_crossbar.style.width
          end
          pdf.stroke_color! @upper_crossbar.color
          pdf.stroke_style! @upper_crossbar.style
          pdf.line(this_x - cb_width, line_top_y, this_x + cb_width, line_top_y).stroke
        end
        if @lower_crossbar
          if @dot
            cb_width = @dot.style.width
          else
            cb_width = @lower_crossbar.style.width
          end
          pdf.stroke_color! @lower_crossbar.color
          pdf.stroke_style! @lower_crossbar.style

          pdf.line(this_x - cb_width, line_bot_y, this_x + cb_width, line_bot_y).stroke
        end
      end

      pdf.restore_state

      pdf.y = chart_y

      break if leftover_data.nil?

      data = leftover_data
      leftover_data = nil
    end

    pdf.y
  end
end
