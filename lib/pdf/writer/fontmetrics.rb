#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: fontmetrics.rb,v 1.4 2005/06/16 04:28:25 austin Exp $
#++

class PDF::Writer::FontMetrics
  METRICS_PATH = [ File.join(File.dirname(File.expand_path(__FILE__)), 'fonts') ]

  KEYS = %w{FontName FullName FamilyName Weight ItalicAngle IsFixedPitch
            CharacterSet UnderlinePosition UnderlineThickness Version
            EncodingScheme CapHeight XHeight Ascender Descender StdHW StdVW
            StartCharMetrics FontBBox C KPX}
  KEYS.each { |k| attr_accessor k.downcase.intern }

  def initialize
    @kpx      = {}
    @c        = {}
    @version  = 1
    @font_num = nil
  end

  attr_accessor :font_num
  attr_accessor :path
  attr_accessor :differences
  attr_accessor :encoding

  NUMBER = /^[+\-0-9.]+$/o

    # Open the font file and return a PDF::Writer::FontMetrics object
    # containing it. The +font_name+ may specify just a font file or a full
    # path. If a path is specified, that is the only place where the font
    # file will be looked for. 
  def self.open(font_name)
    file  = font_name.gsub(/\\/o, "/")
    dir   = File.dirname(file)
    name  = File.basename(file)

    metrics_path = []

      # Check to see if the directory is "." or a non-path
    if dir == "."
      metrics_path << dir << METRICS_PATH << $LOAD_PATH
    elsif dir !~ %r{^(\w:|/)}o and dir.index("/")
      METRICS_PATH.each { |path| metrics_path << File.join(path, dir) }
      $LOAD_PATH.each { |path| metrics_path << File.join(path, dir) }
    else
      metric_path = [ dir ]
    end
    metrics_path.flatten!

    font = nil
    afm = nil

    metrics_path.each do |path|
      afm_file  = File.join(path, "#{name}.afm").gsub(/\.afm\.afm$/o, ".afm")
      rfm_file  = "#{afm_file}.rfm"

        # Attempt to unmarshal an .afm.rfm file first. If it is loaded,
        # we're in good shape.
      begin
        if File.exists?(rfm_file)
          data = File.open(rfm_file, "rb") { |file| file.read }
          font = Marshal.load(data)
          return font
        end
      rescue
        nil
      end

        # Attempt to open and process the font.
      File.open(afm_file, "rb") do |file|
        font = PDF::Writer::FontMetrics.new

          # An AFM file contains key names followed by valuees.
        file.each do |line|
          line.chomp!
          line.strip!
          key, *values = line.split
          op = "#{key.downcase}=".to_sym

            # I probably need to deal with MetricsSet. The default value is
            # 0, which is writing direction 0 (W0X). If MetricsSet 1 is
            # specified, then only writing direction 1 is present (W1X). If
            # MetricsSet 2 is specified, then both W0X and W1X are present.

            # Measurements are always 1/1000th of a scale factor (point
            # size). So a 12pt character with a width of 222 is going to be
            # 222 * 12 / 1000 or 2.664 points wide.
          case key
          when 'FontName', 'FullName', 'FamilyName', 'Weight',
            'IsFixedPitch', 'CharacterSet', 'Version', 'EncodingScheme'
              # These values are string values.
            font.__send__(op, values.join(" "))
          when 'ItalicAngle', 'UnderlinePosition', 'UnderlineThickness',
            'CapHeight', 'XHeight', 'Ascender', 'Descender', 'StdHW',
            'StdVW', 'StartCharMetrics'
              # These values are floating point values.
            font.__send__(op, values.join(" ").to_f)
          when 'FontBBox'
              # These values are an array of floating point values
            font.fontbbox = values.map { |el| el.to_f }
          when 'C', 'CH'
              # Individual Character Metrics Values:
              #   C  <character number>
              #   CH <hex character number>
              #     One of C or CH must be provided. Specifies the encoding
              #     number for the character. -1 if the character is not
              #     encoded in the font.
              #
              #   WX  <x width number>
              #   W0X <x0 width number>
              #   W1X <x1 width number>
              #     Character width in x for writing direction 0 (WX, W0X)
              #     or 1 (W1X) where y is 0. Optional.
              #
              #   WY  <y width number>
              #   W0Y <y0 width number>
              #   W1Y <y1 width number>
              #     Character width in y for writing direction 0 (WY, W0Y)
              #     or 1 (W1Y) where x is 0. Optional.
              #
              #   W  <x width> <y width>
              #   W0 <x0 width> <y0 width>
              #   W1 <x1 width> <y1 width>
              #     Character width in x, y for writing direction 0 (W, W0)
              #     or 1 (W1). Optional.
              #
              #   VV <x number> <y number>
              #     Same as VVector in the global font definition, but for
              #     this single character. Optional.
              #
              #   N <name>
              #     The PostScript name of the font. Optional.
              #   
              #   B <llx> <lly> <urx> <ury>
              #     Character bounding box for the lower left corner and the
              #     upper right corner. Optional.
              #
              #   L <sucessor> <ligature>
              #     Ligature sequence where both <successor> and <ligature>
              #     are N <names>. For the fragment "N f; L i fi; L l fl",
              #     two ligatures are defined: fi and fl. Optional,
              #     multiples permitted.
              #
              # C 39 ; WX 222 ; N quoteright ; B 53 463 157 718 ;
            bits = line.chomp.strip.split(/;/).collect { |r| r.strip }
            dtmp = {}

            bits.each do |bit|
              b = bit.split
              if b.size > 2
                dtmp[b[0]] = []
                b[1..-1].each do |z|
                  if z =~ NUMBER
                    dtmp[b[0]] << z.to_f
                  else
                    dtmp[b[0]] << z
                  end
                end
              elsif b.size == 2
                if b[0] == 'C' and b[1] =~ NUMBER
                  dtmp[b[0]] = b[1].to_i
                elsif b[0] == 'CH'
                  dtmp['C'] = b[1].to_i(16)
                elsif b[1] =~ NUMBER
                  dtmp[b[0]] = b[1].to_f
                else
                  dtmp[b[0]] = b[1]
                end
              end
            end

            font.c[dtmp['N']] = dtmp
            font.c[dtmp['C']] = dtmp unless dtmp['C'].nil?
          when 'KPX' # KPX Adieresis yacute -40
            # KPX: Kerning Pair
            font.kpx[values[0]] = { }
            font.kpx[values[0]][values[1]] = values[2].to_f
          end
        end
        font.path = afm_file
      end rescue nil # Ignore file errors
      break unless font.nil?
    end

    raise ArgumentError, "Font #{font_name} not found." if font.nil?
    font
  end

    # Save the loaded font metrics file as a binary marshaled value.
  def save_as_rfm
    rfm = File.basename(@path).gsub(/\.afm.*$/, '')
    rfm << ".afm.rfm"
    File.open(rfm, "wb") { |file| file.write Marshal.dump(self) }
  end
end
