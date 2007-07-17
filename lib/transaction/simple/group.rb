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
require 'transaction/simple'

  # A transaction group is an object wrapper that manages a group of objects
  # as if they were a single object for the purpose of transaction
  # management. All transactions for this group of objects should be
  # performed against the transaction group object, not against individual
  # objects in the group.
  #
  # == Transaction Group Usage
  #   require 'transaction/simple/group'
  #   
  #   x = "Hello, you."
  #   y = "And you, too."
  #   
  #   g = Transaction::Simple::Group.new(x, y)
  #   g.start_transaction(:first)     # -> [ x, y ]
  #   g.transaction_open?(:first)     # -> true
  #   x.transaction_open?(:first)     # -> true
  #   y.transaction_open?(:first)     # -> true
  #   
  #   x.gsub!(/you/, "world")         # -> "Hello, world."
  #   y.gsub!(/you/, "me")            # -> "And me, too."
  #   
  #   g.start_transaction(:second)    # -> [ x, y ]
  #   x.gsub!(/world/, "HAL")         # -> "Hello, HAL."
  #   y.gsub!(/me/, "Dave")           # -> "And Dave, too."
  #   g.rewind_transaction(:second)   # -> [ x, y ]
  #   x                               # -> "Hello, world."
  #   y                               # -> "And me, too."
  #   
  #   x.gsub!(/world/, "HAL")         # -> "Hello, HAL."
  #   y.gsub!(/me/, "Dave")           # -> "And Dave, too."
  #   
  #   g.commit_transaction(:second)   # -> [ x, y ]
  #   x                               # -> "Hello, HAL."
  #   y                               # -> "And Dave, too."
  #   
  #   g.abort_transaction(:first)     # -> [ x, y ]
  #   x                               = -> "Hello, you."
  #   y                               = -> "And you, too."
class Transaction::Simple::Group
    # Creates a transaction group for the provided objects. If a block is
    # provided, the transaction group object is yielded to the block; when
    # the block is finished, the transaction group object will be cleared
    # with #clear.
  def initialize(*objects)
    @objects = objects || []
    @objects.freeze
    @objects.each { |obj| obj.extend(Transaction::Simple) }

    if block_given?
      begin
        yield self
      ensure
        self.clear
      end
    end
  end

    # Returns the objects that are covered by this transaction group.
  attr_reader :objects

    # Clears the object group. Removes references to the objects so that
    # they can be garbage collected.
  def clear
    @objects = @objects.dup.clear
  end

    # Tests to see if all of the objects in the group have an open
    # transaction. See Transaction::Simple#transaction_open? for more
    # information.
  def transaction_open?(name = nil)
    @objects.inject(true) do |val, obj|
      val = val and obj.transaction_open?(name)
    end
  end

    # Returns the current name of the transaction for the group.
    # Transactions not explicitly named are named +nil+.
  def transaction_name
    @objects[0].transaction_name
  end

    # Starts a transaction for the group. Stores the current object state.
    # If a transaction name is specified, the transaction will be named.
    # Transaction names must be unique. Transaction names of +nil+ will be
    # treated as unnamed transactions.
  def start_transaction(name = nil)
    @objects.each { |obj| obj.start_transaction(name) }
  end

    # Rewinds the transaction. If +name+ is specified, then the intervening
    # transactions will be aborted and the named transaction will be
    # rewound. Otherwise, only the current transaction is rewound.
  def rewind_transaction(name = nil)
    @objects.each { |obj| obj.rewind_transaction(name) }
  end

    # Aborts the transaction. Resets the object state to what it was before
    # the transaction was started and closes the transaction. If +name+ is
    # specified, then the intervening transactions and the named transaction
    # will be aborted. Otherwise, only the current transaction is aborted.
    #
    # If the current or named transaction has been started by a block
    # (Transaction::Simple.start), then the execution of the block will be
    # halted with +break+ +self+.
  def abort_transaction(name = nil)
    @objects.each { |obj| obj.abort_transaction(name) }
  end

    # If +name+ is +nil+ (default), the current transaction level is closed
    # out and the changes are committed.
    #
    # If +name+ is specified and +name+ is in the list of named
    # transactions, then all transactions are closed and committed until the
    # named transaction is reached.
  def commit_transaction(name = nil)
    @objects.each { |obj| obj.commit_transaction(name) }
  end

    # Alternative method for calling the transaction methods. An optional
    # name can be specified for named transaction support.
    #
    # #transaction(:start)::  #start_transaction
    # #transaction(:rewind):: #rewind_transaction
    # #transaction(:abort)::  #abort_transaction
    # #transaction(:commit):: #commit_transaction
    # #transaction(:name)::   #transaction_name
    # #transaction::          #transaction_open?
  def transaction(action = nil, name = nil)
    @objects.each { |obj| obj.transaction(action, name) }
  end
end
