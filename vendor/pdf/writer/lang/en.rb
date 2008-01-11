#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: en.rb,v 1.9.2.1 2005/08/25 03:38:06 austin Exp $
#++
  # PDF::Writer::Lang::EN is the English-language output module. It contains a
  # hash, @message, that contains the messages that may be reported by any
  # method in the PDF library. The messages are identified by a Symbol.
  #
  # <b>Symbol</b>::         <b>Meaning</b>
  # <b>:uri_09x</b>::       URIs must be HTTP or FTP URIs in this version of RSS.
module PDF::Writer::Lang::EN
  @message = {
    :invalid_pos                    => ":pos must be either :before or :after.",
    :req_FPXO                       => "Pages#<< requires a PDF::Writer::Page, PDF::Writer::Font, or PDF::Writer::ExternalObject.",
    :req_FPXOH                      => "Pages#add requires a PDF::Writer::Page, PDF::Writer::Font, PDF::Writer::ExternalObject, or Hash.",
    :text_width_parameters_reversed => <<-EOS,
  %s
As of PDF::Writer 1.1, the signature for #text_width and #text_line_width
is (text, size), not (size, text). It appears that the old version is still
in use in your code. Please change it.
    EOS
    :add_text_parameters_reversed   => <<-EOS,
  %s
As of PDF::Writer 1.1, the signature for #add_text is (x, y, text, size,
angle, word_space_adjust), not (x, y, size, text, angle, word_space_adjust).
It appears that the old version is still in use in your code. Please change
it.
    EOS
    :add_textw_parameters_reversed  => <<-EOS,
  %s
As of PDF::Writer 1.1, the signature for #add_text_wrap is (x, y, text,
size, justification, angle, test), not (x, y, size, text, justification,
angle, test). It appears that the old version is still in use in your
code. Please change it.
    EOS
    :png_invalid_header             => "Invalid PNG header.",
    :png_unsupp_compres             => "Unsupported PNG compression method.",
    :png_unsupp_filter              => "Unsupported PNG filter method.",
    :png_header_missing             => "PNG information header is missing.",
    :png_8bit_colour                => "Only PNG colour depths of 8 bits or less are supported.",
    :png_interlace                  => "Interlaced PNG images are not currently supported.",
    :png_alpha_trans                => "PNG alpha channel transparency is not supported; only palette transparency is supported.",
    :data_must_be_array             => "The table data is not an Array. (Temporary limitation.)",
    :columns_unspecified            => "Columns are unspecified. They must be data[0] and be an array.",
    :no_zlib_no_compress            => "Could not load Zlib. PDF compression is disabled.",
    :ttf_licence_no_embedding       => "The TrueType font %1s has a licence that does not allow for embedding.",
    :simpletable_columns_undefined  => "Columns are undefined for table.",
    :simpletable_data_empty         => "Table data is empty.",
    :techbook_eval_exception        => <<-EOS,

Error in document around line %d:
  %s
Backtrace:
%s
EOS
    :techbook_bad_columns_directive => "Invalid argument to directive .columns: %s",
    :techbook_cannot_find_document  => "Error: cannot find a document.",
    :techbook_using_default_doc     => "Using default document '%s'.",
    :techbook_using_cached_doc      => "Using cached document '%s'...",
    :techbook_regenerating          => "Cached document is older than source document. Regenerating.",
    :techbook_ignoring_cache        => "Ignoring cached document.",
    :techbook_unknown_xref          => "Unknown cross-reference %s.",
    :techbook_code_not_empty        => "Code is not empty:",
    :techbook_usage_banner          => "Usage: %s [options] [INPUT FILE]",
    :techbook_usage_banner_1        => [
      "INPUT FILE, if not specified, will be 'manual.pwd', either in the",
      "current directory or relative to this file.",
      ""
    ],
    :techbook_help_force_regen      => [
      "Forces the regeneration of the document,",
      "ignoring the cached document version."
    ],
    :techbook_help_no_cache         => [
      "Disables generated document caching.",
    ],
    :techbook_help_compress         => [
      "Compresses the resulting PDF.",
    ],
    :techbook_help_help             => [
      "Shows this text.",
    ],
    :techbook_exception             => "Exception %1s around line %2d.",
    :C_callback_form_error          => "Stand-alone callbacks must be of the form <C:callback />.",
    :c_callback_form_error          => "Paired callbacks must be of the form <c:callback>...</c:callback>.",
    :callback_warning               => "Unknown %1s callback: '%2s'. Ignoring.",
    :charts_stddev_data_empty       => "Charts::StdDev data is empty.",
    :charts_stddev_scale_norange    => "Charts::StdDev::Scale has no range.",
    :charts_stddev_scale_nostep     => "Charts::StdDev::Scale has no step.",
  }

  PDF::Writer::Lang.language = self
end
