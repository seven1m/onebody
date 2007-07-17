#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: procset.rb,v 1.2 2005/05/16 03:59:21 austin Exp $
#++
  # The document Procedure Set. Not necessary in PDF 1.4 or later, but
  # producing applications are recommended to provide the /ProcSet /Resource
  # in any case for older viewers. Viewing applications are *not*
  # recommended to rely on this information being correct.
  #
  # These procedure sets are used only when the content stream is printed to
  # a PostScript output device; the names identify PostScript procedure sets
  # that must be sent to the device to interpret the PDF operators in the
  # content stream. Each element of this array must be one of the following
  # predefined names: 'PDF', 'Text', 'ImageB', 'ImageC', and 'ImageI'. See
  # also Appendix H note 102.
class PDF::Writer::Object::Procset < PDF::Writer::Object
  def initialize(parent)
    super

    @info = ["PDF", "Text"]
    @parent.pages.procset = self
    @parent.procset = self
  end

  # This is to add new items to the procset list, despite the fact that
  # this is considered obselete, the items are required for printing to
  # some PostsCript printers.
  #
  # +p+ may be 'ImageB', 'ImageC', or 'ImageI'.
  def <<(p)
    @info << p
  end

  def to_s
    info = @info.uniq
    res = "\n#{@oid} 0 obj\n["
    @info.each { |k| res << "/#{k} " }
    res << "]\nendobj"
  end
end
