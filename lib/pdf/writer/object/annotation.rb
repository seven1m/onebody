#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: annotation.rb,v 1.2 2005/05/16 03:59:21 austin Exp $
#++
  # An annotation object, this will add an annotation to the current page.
  # initially will support just link annotations.
class PDF::Writer::Object::Annotation < PDF::Writer::Object
  TYPES = [:link, :ilink]

  def initialize(parent, type, rect, label)
    super(parent)

    @type = type
    @rect = rect

    case @type
    when :link
      @action = PDF::Writer::Object::Action.new(parent, label)
    when :ilink
      @action = PDF::Writer::Object::Action.new(parent, label, type)
    end
    parent.current_page.add_annotation(self)
  end

  attr_accessor :type
  attr_accessor :action
  attr_accessor :rect

  def to_s
    res = "\n#{@oid} 0 obj\n<< /Type /Annot"
    res << "\n/Subtype /Link" if TYPES.include?(@type)
    res << "\n/A #{@action.oid} 0 R\n/Border [0 0 0]\n/H /I\n/Rect ["
    @rect.each { |v| res << "%.4f " % v }
    res << "]\n>>\nendobj"
  end
end
