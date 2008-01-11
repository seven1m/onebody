#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: image.rb,v 1.2.2.1 2005/08/25 03:38:06 austin Exp $
#++
require 'pdf/writer/oreader'

# An image object. This will be an /XObject dictionary in the document. This
# includes description and data. The diectionary includes:
#
# Type::              (name, Optional) The type of PDF object that this
#                     dictionary describes; if present, must be /XObject for
#                     an image XObject.
# Subtype::           (name, Required) The type of XObject that this
#                     dictionary describes; must be /Image for an image
#                     /XObject.
# Width::             (integer, Required) The width of the image, in samples.
# Height::            (integer, Required) The height of the image, in samples.
# ColorSpace::        (name or array, Required for images, except those that
#                     use the /JPXDecode filter; not allowed for image
#                     masks) The color space in which image samples are
#                     specified; it can be any type of color space except
#                     /Pattern. If the image uses the JPXDecode filter, this
#                     entry is optional: * If /ColorSpace is present, any
#                     color space specifications in the JPEG2000 data are
#                     ignored. * If /ColorSpace is absent, the color space
#                     specifications in the JPEG2000 data are used. The
#                     /Decode array is also ignored unless /ImageMask is
#                     true.
# BitsPerComponent::  (integer, Required except for image masks and images
#                     that use the JPXDecode filter) The number of bits used
#                     to represent each color component. Only a single value
#                     may be specified; the number of bits is the same for
#                     all color components. Valid values are 1, 2, 4, 8, and
#                     (in PDF 1.5) 16. If /ImageMask is true, this entry is
#                     optional, and if specified, its value must be 1. If
#                     the image stream uses a filter, the value of
#                     BitsPerComponent must be consistent with the size of
#                     the data samples that the filter delivers. In
#                     particular, a CCITTFaxDecode or JBIG2Decode filter
#                     always delivers 1-bit samples, a RunLengthDecode or
#                     DCTDecode filter delivers 8-bit samples, and an
#                     LZWDecode or FlateDecode filter delivers samples of a
#                     specified size if a predictor function is used. If the
#                     image stream uses the JPXDecode filter, this entry is
#                     optional and ignored if present. The bit depth is
#                     determined in the process of decoding the JPEG2000
#                     image.
# Intent::            (name, Optional; PDF 1.1) The name of a color
#                     rendering intent to be used in rendering the image
#                     (see “Rendering Intents” on page 230). Default value:
#                     the current rendering intent in the graphics state.
# ImageMask::         (boolean, Optional) A flag indicating whether the
#                     image is to be treated as an image mask (see Section
#                     4.8.5, “Masked Images”). If this flag is true, the
#                     value of /BitsPerComponent must be 1 and Mask and
#                     /ColorSpace should not be specified; unmasked areas
#                     are painted using the current nonstroking color.
#                     Default value: false.
# Mask::              (stream or array, Optional except for image masks; not
#                     allowed for image masks; PDF 1.3) An image XObject
#                     defining an image mask to be applied to this image
#                     (see “Explicit Masking” on page 321), or an array
#                     specifying a range of colors to be applied to it as a
#                     color key mask (see “Color Key Masking” on page 321).
#                     If ImageMask is true, this entry must not be present.
#                     (See implementation note 51 in Appendix H.)
# Decode::            (array, Optional) An array of numbers describing how
#                     to map image samples into the range of values
#                     appropriate for the image’s color space (see “Decode
#                     Arrays” on page 314). If ImageMask is true, the array
#                     must be either [0 1] or [1 0]; otherwise, its length
#                     must be twice the number of color components required
#                     by ColorSpace. If the image uses the JPXDecode filter
#                     and ImageMask is false, Decode is ignored. Default
#                     value: see “Decode Arrays” on page 314.
# Interpolate::       (boolean, Optional) A flag indicating whether image
#                     interpolation is to be performed (see “Image
#                     Interpolation” on page 316). Default value: false.
# Alternates::        (array, Optional; PDF 1.3) An array of alternate image
#                     dictionaries for this image (see “Alternate Images” on
#                     page 317). The order of elements within the array has
#                     no significance. This entry may not be present in an
#                     image XObject that is itself an alternate image.
# SMask::             (stream, Optional; PDF 1.4) A subsidiary image XObject
#                     defining a soft-mask image (see “Soft-Mask Images” on
#                     page 522) to be used as a source of mask shape or mask
#                     opacity values in the transparent imaging model. The
#                     alpha source parameter in the graphics state
#                     determines whether the mask values are interpreted as
#                     shape or opacity. If present, this entry overrides the
#                     current soft mask in the graphics state, as well as
#                     the image’s Mask entry, if any. (However, the other
#                     transparency related graphics state parameters—blend
#                     mode and alpha constant—remain in effect.) If SMask is
#                     absent, the image has no associated soft mask
#                     (although the current soft mask in the graphics state
#                     may still apply).
# SMaskInData::       (integer, Optional for images that use the JPXDecode
#                     filter, meaningless otherwise; PDF 1.5) A code
#                     specifying how soft-mask information (see “Soft-Mask
#                     Images” on page 522) encoded with image samples should
#                     be used: (0) If present, encoded soft-mask image
#                     information should be ignored. (1) The image’s data
#                     stream includes encoded soft-mask values. An
#                     application can create a soft-mask image from the
#                     information to be used as a source of mask shape or
#                     mask opacity in the transparency imaging model. (2)
#                     The image’s data stream includes color channels that
#                     have been preblended with a background; the image data
#                     also includes an opacity channel. An application can
#                     create a soft-mask image with a Matte entry from the
#                     opacity channel information to be used as a source of
#                     mask shape or mask opacity in the transparency model.
#                     * If this entry has a nonzero value, SMask should not
#                     be specified. See also Section 3.3.8, “JPXDecode
#                     Filter.” Default value: 0.
# Name::              (name, Required in PDF 1.0; optional otherwise) The
#                     name by which this image XObject is referenced in the
#                     XObject subdictionary of the current resource
#                     dictionary (see Section 3.7.2, “Resource
#                     Dictionaries”). Note: This entry is obsolescent and
#                     its use is no longer recommended. (See implementation
#                     note 52 in Appendix H.)
# StructParent::      (integer, Required if the image is a structural
#                     content item; PDF 1.3) The integer key of the image’s
#                     entry in the structural parent tree (see “Finding
#                     Structure Elements from Content Items” on page 797).
# ID::                (string, Optional; PDF 1.3; indirect reference
#                     preferred) The digital identifier of the image’s
#                     parent Web Capture content set (see Section 10.9.5,
#                     “Object Attributes Related to Web Capture”).
# OPI::               (dictionary, Optional; PDF 1.2) An OPI version
#                     dictionary for the image (see Section 10.10.6, “Open
#                     Prepress Interface (OPI)”). If ImageMask is true, this
#                     entry is ignored.
# Metadata::          (stream, Optional; PDF 1.4) A metadata stream
#                     containing metadata for the image (see Section 10.2.2,
#                     “Metadata Streams”).
# OC::                (dictionary, Optional; PDF 1.5) An optional content
#                     group or optional content membership dictionary (see
#                     Section 4.10, “Optional Content”), specifying the
#                     optional content properties for this image XObject.
#                     Before the image is processed, its visibility is
#                     determined based on this entry. If it is determined to
#                     be invisible, the entire image is skipped, as if there
#                     were no Do operator to invoke it.
class PDF::Writer::External::Image < PDF::Writer::External
  attr_reader :label
  attr_reader :image_info

  def initialize(parent, data, image, label)
    super(parent)

    @data = data

    @image_info = image

    @info = {
      'Type'    => '/XObject',
      'Subtype' => '/Image',
      'Width'   => image.width,
      'Height'  => image.height
    }

    case image.format
    when "JPEG"
      case image.channels
      when 1
        @info['ColorSpace'] = '/DeviceGray'
      when 4
        @info['ColorSpace'] = '/DeviceCMYK'
          # This should fix problems with CMYK JPEG colours inverted in
          # Adobe Acrobat. Enable only if appropriate.
#       @info['Decode'] = '[1.0 0.0 1.0 0.0 1.0 0.0 1.0 0.0]'
      else
        @info['ColorSpace'] = '/DeviceRGB'
      end
      @info['Filter'] = '/DCTDecode'
      @info['BitsPerComponent'] = 8
    when "PNG"
      if image.info[:compression_method] != 0
        raise TypeError, PDF::Writer::Lang[:png_unsupp_compres]
      end

      if image.info[:filter_method] != 0
        raise TypeError, PDF::Writer::Lang[:png_unsupp_filter]
      end

      data = data.dup
      data.extend(PDF::Writer::OffsetReader)

      data.read_o(8)  # Skip the default header

      ok      = true
      length  = data.size
      palette = ""
      idat    = ""

      while ok
        chunk_size  = data.read_o(4).unpack("N")[0]
        section     = data.read_o(4)
        case section
        when 'PLTE'
          palette << data.read_o(chunk_size)
        when 'IDAT'
          idat << data.read_o(chunk_size)
        when 'tRNS'
            # This chunk can only occur once and it must occur after the
            # PLTE chunk and before the IDAT chunk
          trans = {}
          case image.info[:color_type]
          when 3
              # Indexed colour, RGB. Each byte in this chunk is an alpha for
              # the palette index in the PLTE ("palette") chunk up until the
              # last non-opaque entry. Set up an array, stretching over all
              # palette entries which will be 0 (opaque) or 1 (transparent).
            trans[:type]  = 'indexed'
            trans[:data]  = data.read_o(chunk_size).unpack("C*")
          when 0
              # Greyscale. Corresponding to entries in the PLTE chunk.
              # Grey is two bytes, range 0 .. (2 ^ bit-depth) - 1
            trans[:grayscale] = data.read_o(2).unpack("n")
            trans[:type]      = 'indexed'
#           trans[:data]      = data.read_o.unpack("C")
          when 2
              # True colour with proper alpha channel.
            trans[:rgb] = data.read_o(6).unpack("nnn")
          end
        else
          data.offset += chunk_size
        end

        ok = (section != "IEND")

        data.read_o(4)  # Skip the CRC
      end

      if image.bits > 8
        raise TypeError, PDF::Writer::Lang[:png_8bit_colour]
      end
      if image.info[:interlace_method] != 0
        raise TypeError, PDF::Writer::Lang[:png_interlace]
      end

      ncolor  = 1
      colour  = 'DeviceRGB'
      case image.info[:color_type]
      when 3
        nil
      when 2
        ncolor = 3
      when 0
        colour = 'DeviceGray'
      else
        raise TypeError, PDF::Writer::Lang[:png_alpha_trans]
      end

      @info['Filter'] = '[/FlateDecode]'
      @info['DecodeParms'] = "[<</Predictor 15 /Colors #{ncolor} /Columns #{image.width}>>]"
      @info['BitsPerComponent'] = image.bits.to_s

      unless palette.empty?
        @info['ColorSpace']  = " [ /Indexed /DeviceRGB #{(palette.size / 3) - 1} "
        contents            = PDF::Writer::Object::Contents.new(parent,
                                                                self)
        contents.data       = palette
        @info['ColorSpace'] << "#{contents.oid} 0 R ]"

        if trans
          case trans[:type]
          when 'indexed'
            @info['Mask']   = " [ #{trans[:data].join(' ')} ] "
          end
        end
      else
        @info['ColorSpace'] = "/#{colour}"
      end

      @data = idat
    end

    @label = label

      # assign it a place in the named resource dictionary as an external
      # object, according to the label passed in with it.
    @parent.pages << self
      # also make sure that we have the right procset object for it.
    @parent.procset << 'ImageC'
  end

  def to_s
    tmp = @data.dup
    res = "\n#{@oid} 0 obj\n<<"
    @info.each { |k, v| res << "\n/#{k} #{v}"}
    if (@parent.encrypted?)
      @parent.arc4.prepare(self)
      tmp = @parent.arc4.encrypt(tmp)
    end
    res << "\n/Length #{tmp.size} >>\nstream\n#{tmp}\nendstream\nendobj\n"
    res
  end
end
