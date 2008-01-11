#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: strokestyle.rb,v 1.5 2005/06/02 21:20:35 austin Exp $
#++
  # A class that represents a style with which lines will be drawn. 
class PDF::Writer::StrokeStyle
  LINE_CAPS   = { :butt => 0, :round => 1, :square => 2 }
  LINE_JOINS  = { :miter => 0, :round => 1, :bevel => 2 }
  SOLID_LINE  = { :pattern => [], :phase => 0 }

  def initialize(width = 1, options = {})
    @width        = width
    @cap          = options[:cap]
    @join         = options[:join]
    @dash         = options[:dash]
    @miter_limit  = options[:miter_limit]

    yield self if block_given?
  end

  DEFAULT = self.new(1, :cap => :butt, :join => :miter, :dash => SOLID_LINE)

    # The thickness of the line in PDF units.
  attr_accessor :width
    # The type of cap to put on the line.
    #
    # <tt>:butt</tt>::    The stroke is squared off at the endpoint of the
    #                     path. There is no projection beyond the end of the
    #                     path.
    # <tt>:round</tt>::   A semicircular arc with a diameter equal to the
    #                     line width is drawn around the endpoint and filled
    #                     in.
    # <tt>:square</tt>::  The stroke continues beyond the endpoint of the
    #                     path for a distance equal to half the line width
    #                     and is squared off.
    # +nil+::             Keeps the current line cap.
  attr_accessor :cap
  def cap=(c) #:nodoc:
    if c.nil? or LINE_CAPS.include?(c)
      @cap = c
    else
      raise ArgumentError, "Line cap styles must be nil (none), butt, round, or square."
    end
  end
    # How two lines join together.
    #
    # <tt>:miter</tt>::   The outer edges of the strokes for the two
    #                     segments are extended until they meet at an angle,
    #                     as in a picture frame. If the segments meet at too
    #                     sharp an angle (as defined by the #miter_limit), a
    #                     bevel join is used instead.
    # <tt>:round</tt>::   An arc of a circle with a diameter equal to the
    #                     line width is drawn around the point where the two
    #                     segments meet, connecting the outer edges of the
    #                     strokes for the two segments. This pie-slice
    #                     shaped figure is filled in, producing a rounded
    #                     corner.
    # <tt>:bevel</tt>::   The two segments are finished with butt caps and
    #                     the the resulting notch beyond the ends of the
    #                     segments is filled with a triangle, forming a
    #                     flattened edge on the join.
    # +nil+::             Keeps the current line join.
  attr_accessor :join
  def join=(j) #:nodoc:
    if j.nil? or LINE_JOINS.include?(j)
      @join = j
    else
      raise ArgumentError, "Line join styles must be nil (none), miter, round, or bevel."
    end
  end
    # When two line segments meet and <tt>:miter</tt> joins have been
    # specified, the miter may extend far beyond the thickness of the line
    # stroking the path. #miter_limit imposes a maximum ratio miter length
    # to line width at which point the join will be converted from a miter
    # to a bevel. Adobe points out that the ratio is directly related to the
    # angle between the segments in user space. With [p] representing the
    # angle at which the segments meet:
    #
    #     miter_length / line_width == 1 / (sin ([p] / 2))
    #
    # A miter limit of 1.414 converts miters to bevels for [p] less than 90
    # degrees, a limit of 2.0 converts them for [p] less than 60 degrees,
    # and a limit of 10.0 converts them for [p] less than approximately 11.5
    # degrees. 
  attr_accessor :miter_limit
    # Controls the pattern of dashes and gaps used to stroke paths. This
    # value must either be +nil+, or a hash with the following values:
    #
    # <tt>:pattern</tt>:: An array of numbers specifying the lengths (in PDF
    #                     userspace units) of alternating dashes and gaps.
    #                     The array is processed cyclically, so that a
    #                     <tt>:pattern</tt> of [3] represents three units
    #                     on, three units off, and a <tt>:pattern</tt> of
    #                     [2, 1] represents two units on, one unit off.
    #
    #       # - represents on, _ represents off
    #     ---___---___---   # pattern [3]
    #     --_--_--_--_--_   # pattern [2, 1]
    #
    # <tt>:phase</tt>::   The offset in the <tt>:pattern</tt> where the
    #                     drawing of the stroke begins. Using a
    #                     <tt>:phase</tt> of 1, the <tt>:pattern</tt> [3]
    #                     will start offset by one phase, for two units on,
    #                     three units off, three units on.
    #
    #     --___---___---_   # pattern [3], phase 1
    #     -_--_--_--_--_-   # pattern [2, 1], phase 1
    #
    # The constant SOLID_LINE may be used to restore line drawing to a solid
    # line; this corresponds to an empty pattern with zero phase ([] 0).
    #
    # Dashed lines wrap around curves and corners just as solid stroked
    # lines do, with normal cap and join handling with no consideration of
    # the dash pattern. A path with several subpaths treats each subpath
    # independently; the complete dash pattern is restarted at the beginning
    # of each subpath.
  attr_accessor :dash

  def render(debug = false)
    s = ""
    s << "#{width} w" if @width > 0
    s << " #{LINE_CAPS[@cap]} J" if @cap
    s << " #{LINE_JOINS[@join]} j" if @join
    s << " #{@miter_limit} M" if @miter_limit
    if @dash
      s << " ["
      @dash[:pattern].each { |len| s << " #{len}" }
      s << " ] #{@dash[:phase] or 0} d"
    end
    s
  end
end
