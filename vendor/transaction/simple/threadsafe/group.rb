#--
# Transaction::Simple
# Simple object transaction support for Ruby
# http://rubyforge.org/projects/trans-simple/
#   Version 1.4.0
#
# Licensed under a MIT-style licence. See Licence.txt in the main
# distribution for full licensing information.
#
# Copyright (c) 2003 - 2007 Austin Ziegler
#
# $Id: group.rb 47 2007-02-03 15:02:51Z austin $
#++
require 'transaction/simple/threadsafe'

  # A transaction group is an object wrapper that manages a group of objects
  # as if they were a single object for the purpose of transaction
  # management. All transactions for this group of objects should be
  # performed against the transaction group object, not against individual
  # objects in the group. This is the threadsafe version of a transaction
  # group.
class Transaction::Simple::ThreadSafe::Group < Transaction::Simple::Group
  def initialize(*objects)
    @objects = objects || []
    @objects.freeze
    @objects.each { |obj| obj.extend(Transaction::Simple::ThreadSafe) }

    if block_given?
      begin
        yield self
      ensure
        self.clear
      end
    end
  end
end
