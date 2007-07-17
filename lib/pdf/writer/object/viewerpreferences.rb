#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: viewerpreferences.rb,v 1.2 2005/05/16 03:59:21 austin Exp $
#++
  # Set the viewer preferences. 
  # 
  # HideToolbar::   boolean (Optional) A flag specifying whether to hide the
  #                 viewer application? tool bars when the document is
  #                 active. Default value: false.
  # HideMenubar::   boolean (Optional) A flag specifying whether to hide the
  #                 viewer application? menu bar when the document is
  #                 active. Default value: false.
  # HideWindowUI::  boolean (Optional) A flag specifying whether to hide
  #                 user interface elements in the document? window (such as
  #                 scroll bars and navigation controls), leaving only the
  #                 document? contents displayed. Default value: false.
  # FitWindow::     boolean (Optional) A flag specifying whether to resize
  #                 the document? window to fit the size of the first
  #                 displayed page. Default value: false.
  # CenterWindow::  boolean (Optional) A flag specifying whether to position
  #                 the document? window in the center of the screen.
  #                 Default value: false.
  # NonFullScreenPageMode:: name (Optional) The document? page mode,
  #                         specifying how to display the document on
  #                         exiting full-screen mode. This entry is
  #                         meaningful only if the value of the PageMode
  #                         entry in the catalog dictionary is FullScreen;
  #                         it is ignored otherwise. Default value: UseNone.
  # Direction::             name (Optional; PDF 1.3) The predominant reading
  #                         order for text: L2R Left to right R2L Right to
  #                         left (including vertical writing systems such as
  #                         Chinese, Japanese, and Korean) This entry has no
  #                         direct effect on the document? contents or page
  #                         numbering, but can be used to determine the
  #                         relative positioning of pages when displayed
  #                         side by side or printed n-up. Default value:
  #                         L2R.
  #
  # NonFullScreenPageMode Names
  # UseNone:: Neither document outline nor thumbnail images visible
  # UseOutlines:: Document outline visible
  # UseThumbs:: Thumbnail images visible
  #
  # Note that boolean values are represented by the values 'true' and
  # 'false'. Also note that I have not done much testing on changing these
  # values and am not sure how responsive the various viewers and browsers
  # are to them (and setting the direction would be fairly meaningless as
  # none of these character sets are avaliable yet.
class PDF::Writer::Object::ViewerPreferences < PDF::Writer::Object
  Preferences = %w{HideToolbar HideMenubar HideWindowUI FitWindow CenterWindow NonFullScreenPageMode Direction}

  def initialize(parent)
    super(parent)
  end

  Preferences.each do |s|
    attr_accessor s.downcase.intern
  end

  def to_s
    res = "\n#{@id} 0 obj\n<< "
    Preferences.each do |s|
      v = __send__("#{s.downcase}".intern)
      res << "\n/#{s} /#{v}" unless v.nil?
    end
    res << "\n>>\n"
  end
end
