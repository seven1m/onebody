#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: graphics.rb,v 1.12.2.1 2005/08/25 03:38:05 austin Exp $
#++
  # Points for use in the drawing of polygons.
class PDF::Writer::PolygonPoint
  def initialize(x, y, connector = :line)
    @x, @y, @connector = x, y, connector
  end

  attr_reader :x, :y, :connector
end

  # This module contains graphics primitives. Objects that include this
  # module must respond to #add_content.
  #
  # The PDF::Writer coordinate system is in PDF userspace units. The
  # coordinate system in PDF::Writer is slightly different than might be
  # expected, in that <tt>(0, 0)</tt> is at the lower left-hand corner of
  # the canvas (page), not the normal top left-hand corner of the canvas.
  # (See the diagram below.)
  #
  #     Y     Y
  #    0+-----+X
  #     |     |
  #     |     |
  #     |     |
  #    0+-----+X
  #     0     0
  #
  # Each primitive provided below indicates the <em>New Point</em>, or the
  # coordinates new drawing point at the completion of the drawing
  # operation. Drawing operations themselves do *not* draw or fill the path.
  # This must be done by one of the stroke or fill operators, #stroke,
  # #close_stroke, #fill, #close_fill, #fill_stroke, or #close_fill_stroke.
  #
  # Drawing operations return +self+ (the canvas) so that operations may be
  # chained.
module PDF::Writer::Graphics
    # Close the current path by appending a straight line segment from the
    # drawing point to the starting point of the path. If the path is
    # closed, this does nothing. This operator terminates the current
    # subpath.
  def close
    add_content(" h")
    self
  end

    # Stroke the path. This operation terminates a path object and draws it.
  def stroke
    add_content(" S")
    self
  end

    # Close the current path by appending a straight line segment from the
    # drawing point to the starting point of the path, and then stroke it.
    # This does the same as #close followed by #stroke.
  def close_stroke
    add_content(" s")
    self
  end

    # Fills the path. Open subpaths are implicitly closed before being
    # filled. PDF offers two methods for determining the fill region. The
    # first is called the "nonzero winding number" and is the default fill.
    # The second is called "even-odd".
    #
    # Use the even-odd rule (called with <tt>#fill(:even_odd)</tt>) with
    # caution, as this will cause certain portions of the path to be
    # considered outside of the fill region, resulting in interesting cutout
    # patterns.
  def fill(rule = nil)
    if :even_odd == rule
      add_content(" f*")
    else
      add_content(" f")
    end
    self
  end

    # Close the current path by appending a straight line segment from the
    # drawing point to the starting point of the path, and then fill it.
    # This does the same as #close followed by #fill.
    #
    # See #fill for more information on fill rules.
  def close_fill(rule = nil)
    close
    fill(rule)
    self
  end

    # Fills and then strokes the path. Open subpaths are implicitly closed
    # before being filled. This is the same as constructing two identical
    # path objects, calling #fill on one and #stroke on the other. Paths
    # filled and stroked in this manner are treated as if they were one
    # object for PDF transparency purposes (the PDF transparency model is
    # not yet supported by PDF::Writer).
    #
    # See #fill for more information on fill rules.
  def fill_stroke(rule = nil)
    if :even_odd == rule
      add_content(" B*")
    else
      add_content(" B")
    end
    self
  end

    # Closes, fills and then strokes the path. Open subpaths are explicitly
    # closed before being filled (as if #close and then #fill_stroke had
    # been called). This is the same as constructing two identical path
    # objects, calling #fill on one and #stroke on the other. Paths filled
    # and stroked in this manner are treated as if they were one object for
    # PDF transparency purposes (PDF transparency is not yet supported by
    # PDF::Writer).
    #
    # See #fill for more information on fill rules.
  def close_fill_stroke(rule = nil)
    if :even_odd == rule
      add_content(" b*")
    else
      add_content(" b")
    end
    self
  end

    # Move the drawing point to the specified coordinates <tt>(x, y)</tt>.
    #
    # New Point:: <tt>(x, y)</tt>
    # Subpath::   New
  def move_to(x, y)
    add_content("\n%.3f %.3f m" % [ x, y ])
    self
  end

    # Draw a straight line from the drawing point to <tt>(x, y)</tt>.
    #
    # New Point:: <tt>(x, y)</tt>
    # Subpath::   Current
  def line_to(x, y)
    add_content("\n%.3f %.3f l" % [ x, y ])
    self
  end

    # Draws a cubic Bezier curve from the drawing point to <tt>(x2, y2)</tt>
    # using <tt>(x0, y0)</tt> and <tt>(x1, y1)</tt> as the control points
    # for the curve.
    #
    # New Point:: <tt>(x2, y2)</tt>
    # Subpath::   Current
  def curve_to(x0, y0, x1, y1, x2, y2)
    add_content("\n%.3f %.3f %.3f %.3f %.3f %.3f c" % [ x0, y0, x1, y1, x2, y2 ])
    self
  end

    # Draws a cubic Bezier curve from the drawing point to <tt>(x1, y1)</tt>
    # using the drawing point and <tt>(x0, y0)</tt> as the control points
    # for the curve.
    #
    # New Point:: <tt>(x1, y1)</tt>
    # Subpath::   Current
  def scurve_to(x0, y0, x1, y1)
    add_content("\n%.3f %.3f %.3f %.3f v" % [ x0, y0, x1, y1 ])
    self
  end

    # Draws a cubic Bezier curve from the drawing point to <tt>(x1, y1)</tt>
    # using <tt>(x0, y0)</tt> and <tt>(x1, y1)</tt> as the control points
    # for the curve.
    #
    # New Point:: <tt>(x1, y1)</tt>
    # Subpath::   Current
  def ecurve_to(x0, y0, x1, y1)
    add_content("\n%.3f %.3f %.3f %.3f y" % [ x0, y0, x1, y1 ])
    self
  end

    # Draw a straight line from <tt>(x0, y0)</tt> to <tt>(x1, y1)</tt>. The
    # line is a new subpath.
    #
    # New Point:: <tt>(x1, y1)</tt>.
    # Subpath::   New
  def line(x0, y0, x1, y1)
    move_to(x0, y0).line_to(x1, y1)
  end

    # Draw a cubic Bezier curve from <tt>(x0, y0)</tt> to <tt>(x3, y3)</tt>
    # using <tt>(x1, y1)</tt> and <tt>(x2, y2)</tt> as control points.
    #
    # New Point:: <tt>(x3, y3)</tt>
    # Subpath::   New
  def curve(x0, y0, x1, y1, x2, y2, x3, y3)
    move_to(x0, y0).curve_to(x1, y1, x2, y2, x3, y3)
  end

    # Draw a cubic Bezier curve from <tt>(x0, y0)</tt> to <tt>(x2, y2)</tt>
    # using <tt>(x0, y0)</tt> and <tt>(x1, y1)</tt> as control points.
    #
    # New Point:: <tt>(x2, y2)</tt>
    # Subpath::   New
  def scurve(x0, y0, x1, y1, x2, y2)
    move_to(x0, y0).scurve_to(x1, y1, x2, y2)
  end

    # Draw a cubic Bezier curve from <tt>(x0, y0)</tt> to <tt>(x2, y2)</tt>
    # using <tt>(x1, y1)</tt> and <tt>(x2, y2)</tt> as control points.
    #
    # New Point:: <tt>(x2, y2)</tt>
    # Subpath::   New
  def ecurve(x0, y0, x1, y1, x2, y2)
    move_to(x0, y0).ecurve_to(x1, y1, x2, y2)
  end

    # This constant is used to approximate a symmetrical arc using a cubic
    # Bezier curve.
  KAPPA = 4.0 * ((Math.sqrt(2) - 1.0) / 3.0)

    # Draws a circle of radius +r+ with the centre-point at <tt>(x, y)</tt>
    # as a complete subpath. The drawing point will be moved to the
    # centre-point upon completion of the drawing the circle.
  def circle_at(x, y, r)
    ellipse_at(x, y, r, r)
  end

    # Draws an ellipse of +x+ radius <tt>r1</tt> and +y+ radius <tt>r2</tt>
    # with the centre-point at <tt>(x, y)</tt> as a complete subpath. The
    # drawing point will be moved to the centre-point upon completion of the
    # drawing the ellipse.
  def ellipse_at(x, y, r1, r2 = r1)
    l1 = r1 * KAPPA
    l2 = r2 * KAPPA
    move_to(x + r1, y)
      # Upper right hand corner
    curve_to(x + r1, y + l1, x + l2, y + r2, x,      y + r2)
      # Upper left hand corner
    curve_to(x - l2, y + r2, x - r1, y + l1, x - r1, y)
      # Lower left hand corner
    curve_to(x - r1, y - l1, x - l2, y - r2, x,      y - r2)
      # Lower right hand corner
    curve_to(x + l2, y - r2, x + r1, y - l1, x + r1, y)
    move_to(x, y)
  end

    # Draw an ellipse centered at <tt>(x, y)</tt> with +x+ radius
    # <tt>r1</tt> and +y+ radius <tt>r2</tt>. A partial ellipse can be drawn
    # by specifying the starting and finishing angles.
    #
    # New Point:: <tt>(x, y)</tt>
    # Subpath::   New
  def ellipse2_at(x, y, r1, r2 = r1, start = 0, stop = 359.99, segments = 8)
    segments = 2 if segments < 2

    start = PDF::Math.deg2rad(start)
    stop  = PDF::Math.deg2rad(stop)

    arc     = stop - start
    segarc  = arc / segments.to_f
    dtm     = segarc / 3.0

    theta = start
    a0 = x + r1 * Math.cos(theta)
    b0 = y + r2 * Math.sin(theta)
    c0 = -r1 * Math.sin(theta)
    d0 = r2 * Math.cos(theta)

    move_to(a0, b0)

    (1..segments).each do |ii|
      theta = ii * segarc + start

      a1 = x + r1 * Math.cos(theta)
      b1 = y + r2 * Math.sin(theta)
      c1 = -r1 * Math.sin(theta)
      d1 = r2 * Math.cos(theta)

      curve_to(a0 + (c0 * dtm),
               b0 + (d0 * dtm),
               a1 - (c1 * dtm),
               b1 - (d1 * dtm), a1, b1)

      a0 = a1
      b0 = b1
      c0 = c1
      d0 = d1
    end

    move_to(x, y)
    self
  end

    # Draws an ellipse segment. Draws a closed partial ellipse.
    #
    # New Point:: <tt>(x, y)</tt>
    # Subpath::   New
  def segment_at(x, y, r1, r2 = r1, start = 0, stop = 360, segments = 8)
    ellipse2_at(x, y, r1, r2, start, stop, segments)

    start = PDF::Math.deg2rad(start)
    stop  = PDF::Math.deg2rad(stop)

    ax = x + r1 * Math.cos(start)
    ay = y + r2 * Math.sin(start)
    bx = x + r1 * Math.cos(stop)
    by = y + r2 * Math.sin(stop)

    move_to(ax, ay)
    line_to(x, y)
    line_to(bx, by)
    move_to(x, y)
    self
  end

    # Draw a polygon. +points+ is an array of PolygonPoint objects, or an
    # array that can be converted to an array of PolygonPoint objects with
    # <tt>PDF::Writer::PolygonPoint.new(*value)</tt>.
    #
    # New Point:: <tt>(points[-1].x, points[-1].y)</tt>
    # Subpath::   New
  def polygon(points)
    points = points.map { |pp|
      pp.kind_of?(Array) ? PDF::Writer::PolygonPoint.new(*pp) : pp
    }

    point = points.shift

    move_to(point.x, point.y)

    while not points.empty?
      point = points.shift

      case point.connector
      when :curve
        c1 = point
        c2 = points.shift
        point = points.shift

        curve_to(c1.x, c1.y, c2.x, c2.y, point.x, point.y)
      when :scurve
        c1 = point
        point = points.shift
        scurve_to(c1.x, c1.y, point.x, point.y)
      when :ecurve
        c1 = point
        point = points.shift
        ecurve_to(c1.x, c1.y, point.x, point.y)
      else
        line_to(point.x, point.y)
      end
    end

    self
  end

    # Draw a rectangle. The first corner is <tt>(x, y)</tt> and the second
    # corner is <tt>(x + w, y - h)</tt>.
    #
    # New Point:: <tt>(x + w, y - h)</tt>
    # Subpath::   Current
  def rectangle(x, y, w, h = w)
    add_content("\n%.3f %.3f %.3f %.3f re" % [ x, y, w, h ])
    self
  end

    # Draw a rounded rectangle with corners <tt>(x, y)</tt> and <tt>(x + w,
    # y - h)</tt> and corner radius +r+. The radius should be significantly
    # smaller than +h+ and +w+.
    #
    # New Point:: <tt>(x + w, y - h)</tt>
    # Subpath::   New
  def rounded_rectangle(x, y, w, h, r)
    x1 = x
    x2 = x1 + w
    y1 = y
    y2 = y1 - h

    r1 = r
    r2 = r / 2.0

    points = [
      [ x1 + r1, y1,      :line  ],
      [ x2 - r1, y1,      :line  ],
      [ x2 - r2, y1,      :curve ], # cp1
      [ x2,      y1 - r2,        ], # cp2
      [ x2,      y1 - r1,        ], # ep
      [ x2,      y2 + r1, :line  ],
      [ x2,      y2 + r2, :curve ], # cp1
      [ x2 - r2, y2,             ], # cp2
      [ x2 - r1, y2,             ], # ep
      [ x1 + r1, y2,      :line  ],
      [ x1 + r2, y2,      :curve ], # cp1
      [ x1,      y2 + r2,        ], # cp2
      [ x1,      y2 + r1,        ], # ep
      [ x1,      y1 - r1, :line  ],
      [ x1,      y1 - r2, :curve ], # cp1
      [ x1 + r2, y1,             ], # cp2
      [ x1 + r1, y1,             ], # ep
    ]
    polygon(points)
    move_to(x2, y2)
    self
  end
  
    # Draws a star centered on <tt>(x, y)</tt> with +rays+ portions of
    # +length+ from the centre. Stars with an odd number of rays should have
    # the top ray pointing toward the top of the document. This will not
    # create a "star" with fewer than four points.
    #
    # New Point:: <tt>(cx, cy)</tt>
    # Subpath::   New
  def star(cx, cy, length, rays = 5)
    rays = 4 if rays < 4
    points = []
    part = Math::PI / rays.to_f

    0.step((rays * 4), 2) do |ray|
      if ((ray / 2) % 2 == 0)
        dist = length / 2.0
      else
        dist = length
      end

      x = cx + Math.cos((1.5 + ray / 2.0) * part) * dist
      y = cy + Math.sin((1.5 + ray / 2.0) * part) * dist
      points << [ x, y ]
    end

    polygon(points)
    move_to(cx, cy)
    self
  end

    # This sets the line drawing style. This *must* be a
    # PDF::Writer::StrokeStyle object.
  def stroke_style(style)
    stroke_style!(style) if @current_stroke_style.nil? or style != @current_stroke_style
  end

    # Forces the line drawing style to be set, even if it's the same as the
    # current color. Emits the current stroke style if +nil+ is provided.
  def stroke_style!(style = nil)
    @current_stroke_style = style if style
    add_content "\n#{@current_stroke_style.render}" if @current_stroke_style
  end

    # Returns the current stroke style.
  def stroke_style?
    @current_stroke_style
  end

    # Set the text rendering style. This may be one of the following
    # options:
    #
    # 0:: fill
    # 1:: stroke
    # 2:: fill then stroke
    # 3:: invisible
    # 4:: fill and add to clipping path
    # 5:: stroke and add to clipping path
    # 6:: fill and stroke and add to clipping path
    # 7:: add to clipping path
  def text_render_style(style)
    text_render_style!(style) unless @current_text_render_style and style == @current_text_render_style
  end

    # Forces the text rendering style to be set, even if it's the same as
    # the current style.
  def text_render_style!(style)
    @current_text_render_style = style
  end

    # Reutnrs the current text rendering style.
  def text_render_style?
    @current_text_render_style
  end

    # Sets the color for fill operations.
  def fill_color(color)
    fill_color!(color) if @current_fill_color.nil? or color != @current_fill_color
  end

    # Forces the color for fill operations to be set, even if the color 
    # is the same as the current color. Does nothing if +nil+ is provided.
  def fill_color!(color = nil)
    if color
      @current_fill_color = color
      add_content "\n#{@current_fill_color.pdf_fill}"
    end
  end

    # Returns the current fill color.
  def fill_color?
    @current_fill_color
  end

    # Sets the color for stroke operations.
  def stroke_color(color)
    stroke_color!(color) if @current_stroke_color.nil? or color != @current_stroke_color
  end

    # Forces the color for stroke operations to be set, even if the color
    # is the same as the current color. Does nothing if +nil+ is provided.
  def stroke_color!(color = nil)
    if color
      @current_stroke_color = color
      add_content "\n#{@current_stroke_color.pdf_stroke}"
    end
  end

    # Returns the current stroke color.
  def stroke_color?
    @current_stroke_color
  end

    # Add an image from a file to the current page at position <tt>(x,
    # y)</tt> (the upper left-hand corner of the image). The image will be
    # scaled to +width+ by +height+ units. The image may be a PNG or JPEG
    # image.
    #
    # The +image+ parameter may be a filename or an object that returns the
    # full image data when #read is called with no parameters (such as an IO
    # object). If 'open-uri' is loaded, then the image name may be an URI.
    #
    # In PDF::Writer 1.1 or later, the new +link+ parameter is a hash with
    # two keys:
    #
    # <tt>:type</tt>::    The type of link, either <tt>:internal</tt> or
    #                     <tt>:external</tt>.
    # <tt>:target</tt>::  The destination of the link. For an
    #                     <tt>:internal</tt> link, this is an internal
    #                     cross-reference destination. For an
    #                     <tt>:external</tt> link, this is an URI.
    #
    # This will automatically make the image a clickable link if set.
  def add_image_from_file(image, x, y, width = nil, height = nil, link = nil)
    data = nil

    if image.respond_to?(:read)
      data = image.read
    else
      open(image, 'rb') { |ff| data = ff.read }
    end

    add_image(data, x, y, width, height, nil, link)
  end

    # Add an image from a loaded image (JPEG or PNG) resource at position
    # <tt>(x, y)</tt> (the upper left-hand corner of the image) and scaled
    # to +width+ by +height+ units. If provided, +image_info+ is a
    # PDF::Writer::Graphics::ImageInfo object.
    #
    # In PDF::Writer 1.1 or later, the new +link+ parameter is a hash with
    # two keys:
    #
    # <tt>:type</tt>::    The type of link, either <tt>:internal</tt> or
    #                     <tt>:external</tt>.
    # <tt>:target</tt>::  The destination of the link. For an
    #                     <tt>:internal</tt> link, this is an internal
    #                     cross-reference destination. For an
    #                     <tt>:external</tt> link, this is an URI.
    #
    # This will automatically make the image a clickable link if set.
  def add_image(image, x, y, width = nil, height = nil, image_info = nil, link = nil)
    if image.kind_of?(PDF::Writer::External::Image)
      label       = image.label
      image_obj   = image
      image_info ||= image.image_info
    else
      image_info ||= PDF::Writer::Graphics::ImageInfo.new(image)

      tt = Time.now
      @images << tt
      id = @images.index(tt)
      label = "I#{id}"
      image_obj = PDF::Writer::External::Image.new(self, image, image_info, label)
      @images[id] = image_obj
    end

    if width.nil? and height.nil?
      width   = image_info.width
      height  = image_info.height
    end

    width  ||= height / image_info.height.to_f * image_info.width
    height ||= width * image_info.height / image_info.width.to_f

    tt = "\nq\n%.3f 0 0 %.3f %.3f %.3f cm\n/%s Do\nQ"
    add_content(tt % [ width, height, x, y, label ])

    if link
      case link[:type]
      when :internal
        add_internal_link(link[:target], x, y, x + width, y + height)
      when :external
        add_link(link[:target], x, y, x + width, y + height)
      end
    end

    image_obj
  end

    # Add an image easily to a PDF document. +image+ is the name of a JPG or
    # PNG image. +options+ is a Hash:
    #
    # <tt>:pad</tt>::           The number of PDF userspace units that will
    #                           be on all sides of the image. The default is
    #                           <tt>5</tt> units.
    # <tt>:width</tt>::         The desired width of the image. The image
    #                           will be resized to this width with the
    #                           aspect ratio kept. If unspecified, the
    #                           image's natural width will be used.
    # <tt>:resize</tt>::        How to resize the image, either :width
    #                           (resizes the image to be as wide as the
    #                           margins) or :full (resizes the image to be
    #                           as large as possible). May be a numeric
    #                           value, used as a multiplier for the image
    #                           size (e.g., 0.5 will shrink the image to
    #                           half-sized). If this and <tt>:width</tt> are
    #                           unspecified, the image's natural size will be
    #                           used. Mutually exclusive with the
    #                           <tt>:width<tt> option.
    # <tt>:justification</tt>:: The placement of the image. May be :center,
    #                           :right, or :left. Defaults to :left.
    # <tt>:border</tt>::        The border options. No default border. If
    #                           specified, must be either +true+, which uses
    #                           the default border, or a Hash.
    # <tt>:link</tt>::          Makes the image a clickable link.
    #
    # Image borders are specified as a hash with two options:
    #
    # <tt>:color</tt>:: The colour of the border. Defaults to 50% grey.
    # <tt>:style</tt>:: The stroke style of the border. This must be a
    #                   StrokeStyle object and defaults to the default line.
    #
    # Image links are defined as a hash with two options:
    #
    # <tt>:type</tt>::    The type of link, either <tt>:internal</tt> or
    #                     <tt>:external</tt>.
    # <tt>:target</tt>::  The destination of the link. For an
    #                     <tt>:internal</tt> link, this is an internal
    #                     cross-reference destination. For an
    #                     <tt>:external</tt> link, this is an URI.
  def image(image, options = {})
    width   = options[:width]
    pad     = options[:pad]           || 5
    resize  = options[:resize]
    just    = options[:justification] || :left
    border  = options[:border]
    link    = options[:link]

    if image.kind_of?(PDF::Writer::External::Image)
      info        = image.image_info
      image_data  = image
    else
      if image.respond_to?(:read)
        image_data = image.read
      else
        image_data = open(image, "rb") { |file| file.read }
      end
      info = PDF::Writer::Graphics::ImageInfo.new(image_data)
    end

    raise "Unsupported Image Type" unless %w(JPEG PNG).include?(info.format)

    width   = info.width if width.nil?
    aspect  = info.width.to_f / info.height.to_f

      # Get the maximum width of the image on insertion.
    if @columns_on
      max_width = @columns[:width] - (pad * 2)
    else
      max_width = @page_width - (pad * 2) - @left_margin - @right_margin
    end

    if resize == :full or resize == :width or width > max_width
      width = max_width
    end

      # Keep the height in an appropriate aspect ratio of the width.
    height = (width / aspect.to_f)

      # Resize the image.
    if resize.kind_of?(Numeric)
      width   *= resize
      height  *= resize
    end

      # Resize the image *again*, if it is wider than what is available.
    if width > max_width
      height = (width / aspect.to_f)
    end

      # If the height is greater than the available space:
    havail = @y - @bottom_margin - (pad * 2)
    if height > havail
        # If the image is to be resized to :full (remaining space
        # available), adjust the image size appropriately. Otherwise, start
        # a new page and flow to the next page.
      if resize == :full
        height = havail
        width = (height * aspect)
      else
        start_new_page
      end
    end

      # Find the x and y positions.
    y = @y - pad - height
    x = @left_margin + pad

    if (width < max_width)
      case just
      when :center
        x += (max_width - width) / 2.0
      when :right
        x += (max_width - width)
      end
    end

    image_obj = add_image(image_data, x, y, width, height, info)

    if border
      border = {} if true == border
      border[:color]  ||= Color::RGB::Grey50
      border[:style]  ||= PDF::Writer::StrokeStyle::DEFAULT

      save_state
      stroke_color border[:color] 
      stroke_style border[:style] 
      rectangle(x, y - pad, width, height - pad).stroke
      restore_state
    end

    if link
      case link[:type]
      when :internal
        add_internal_link(link[:target], x, y - pad, x + width, y + height - pad)
      when :external
        add_link(link[:target], x, y - pad, x + width, y + height - pad)
      end
    end

    @y = @y - pad - height

    image_obj
  end

    # Translate the coordinate system axis by the specified user space
    # coordinates.
  def translate_axis(x, y)
    add_content("\n1 0 0 1 %.3f %.3f cm" % [ x, y ])
    self
  end

    # Rotate the axis of the coordinate system by the specified clockwise
    # angle.
  def rotate_axis(angle)
    rad = PDF::Math.deg2rad(angle)
    tt  = "\n%.3f %.3f %.3f %.3f 0 0 cm"
    tx  = [ Math.cos(rad), Math.sin(rad), -Math.sin(rad), Math.cos(rad) ]
    add_content(tt % tx)
    self
  end

    # Scale the coordinate system axis by the specified factors.
  def scale_axis(x = 1, y = 1)
    add_content("\n%.3f 0 0 %.3f 0 0 cm" % [ x, y ])
    self
  end

    # Skew the coordinate system axis by the specified angles.
  def skew_axis(xangle = 0, yangle = 0)
    xr = PDF::Math.deg2rad(xangle)
    yr = PDF::Math.deg2rad(yangle)

    xr = Math.tan(xr) if xangle != 0
    yr = Math.tan(yr) if yangle != 0

    add_content("\n1 %.3f %.3f 1 0 0 cm" % [ xr, yr ])
    self
  end

    # Transforms the coordinate axis with the appended matrix. All
    # transformations (including those above) are performed with this
    # matrix. The transformation matrix is:
    #
    #   +-     -+
    #   | a c e |
    #   | b d f |
    #   | 0 0 1 |
    #   +-     -+
    #
    # The six values are represented as a six-digit vector: [ a b c d e f ]
    #
    # * Axis translation uses [ 1 0 0 1 x y ] where x and y are the new
    #   (0,0) coordinates in the old axis system.
    # * Scaling uses [ sx 0 0 sy 0 0 ] where sx and sy are the scaling
    #   factors.
    # * Rotation uses [ cos(a) sin(a) -sin(a) cos(a) 0 0 ] where a is the
    #   angle, measured in radians.
    # * X axis skewing uses [ 1 0 tan(a) 1 0 0 ] where a is the angle,
    #   measured in radians.
    # * Y axis skewing uses [ 1 tan(a) 0 1 0 0 ] where a is the angle,
    #   measured in radians.
  def transform_matrix(a, b, c, d, e, f)
    add_content("\n%.3f %.3f %.3f %.3f %.3f %.3f cm" % [ a, b, c, d, e, f ])
  end
end
