#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: lang.rb,v 1.1 2005/05/18 11:57:58 austin Exp $
#++

module PDF::Writer::Lang
  @message = {}

  class << self
      # PDF::Writer is fully internationalized. This module method sets the
      # error messages to the specified language Module. The language Module
      # must have a constant Hash called +Message+ containing a set of
      # symbols and localized versions of the messages associated with them.
      #
      # If the file 'pdf/writer/lang/es' contains the module
      # <tt>PDF::Writer::Lang::ES</tt>, the error messages for PDF could be
      # localized to Español thus:
      #
      #   require 'pdf/writer'
      #   require 'pdf/writer/lang/es'
      #
      # Localization is module-global; in a multithreaded program, all
      # threads will use the current language's messages.
      #
      # See PDF::Writer::Lang::EN for more information.
    attr_accessor :language
    def language=(ll) #:nodoc:
      @language = ll
      @message.replace ll.instance_variable_get('@message')
    end

      # Looks up the mesasge
    def [](message_id)
      @message[message_id]
    end
  end
end
