# :title: Transaction::Simple -- Active Object Transaction Support for Ruby
# :main: Readme.txt

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
# $Id: simple.rb 50 2007-02-03 20:26:19Z austin $
#++

# The "Transaction" namespace can be used for additional transaction support
# objects and modules.
module Transaction
  # A standard exception for transaction errors.
  class TransactionError < StandardError; end
  # The TransactionAborted exception is used to indicate when a transaction
  # has been aborted in the block form.
  class TransactionAborted < Exception; end
  # The TransactionCommitted exception is used to indicate when a
  # transaction has been committed in the block form.
  class TransactionCommitted < Exception; end

  te = "Transaction Error: %s"

  Messages = { #:nodoc:
    :bad_debug_object => te % "the transaction debug object must respond to #<<.",
    :unique_names => te % "named transactions must be unique.",
    :no_transaction_open => te % "no transaction open.",
    :cannot_rewind_no_transaction => te % "cannot rewind; there is no current transaction.",
    :cannot_rewind_named_transaction => te % "cannot rewind to transaction %s because it does not exist.",
    :cannot_rewind_transaction_before_block => te % "cannot rewind a transaction started before the execution block.",
    :cannot_abort_no_transaction => te % "cannot abort; there is no current transaction.",
    :cannot_abort_transaction_before_block => te % "cannot abort a transaction started before the execution block.",
    :cannot_abort_named_transaction => te % "cannot abort nonexistant transaction %s.",
    :cannot_commit_no_transaction => te % "cannot commit; there is no current transaction.",
    :cannot_commit_transaction_before_block => te % "cannot commit a transaction started before the execution block.",
    :cannot_commit_named_transaction => te % "cannot commit nonexistant transaction %s.",
    :cannot_start_empty_block_transaction => te % "cannot start a block transaction with no objects.",
    :cannot_obtain_transaction_lock => te % "cannot obtain transaction lock for #%s.",
  }
end

# = Transaction::Simple for Ruby
# Simple object transaction support for Ruby
module Transaction::Simple
  TRANSACTION_SIMPLE_VERSION = '1.4.0'

  class << self
    # Sets the Transaction::Simple debug object. It must respond to #<<.
    # Debugging will be performed automatically if there's a debug object.
    def debug_io=(io)
      if io.nil?
        @tdi        = nil
        @debugging  = false
      else
        raise Transaction::TransactionError, Transaction::Messages[:bad_debug_object] unless io.respond_to?(:<<)
        @tdi = io
        @debugging = true
      end
    end

    # Returns +true+ if we are debugging.
    def debugging?
      defined? @debugging and @debugging
    end

    # Returns the Transaction::Simple debug object. It must respond to #<<.
    def debug_io
      @tdi ||= ""
      @tdi
    end
  end

  # If +name+ is +nil+ (default), then returns +true+ if there is currently
  # a transaction open. If +name+ is specified, then returns +true+ if there
  # is currently a transaction known as +name+ open.
  def transaction_open?(name = nil)
    defined? @__transaction_checkpoint__ or @__transaction_checkpoint__ = nil
    if name.nil?
      Transaction::Simple.debug_io << "Transaction " << "[#{(@__transaction_checkpoint__.nil?) ? 'closed' : 'open'}]\n" if Transaction::Simple.debugging?
      return (not @__transaction_checkpoint__.nil?)
    else
      Transaction::Simple.debug_io << "Transaction(#{name.inspect}) " << "[#{(@__transaction_checkpoint__.nil?) ? 'closed' : 'open'}]\n" if Transaction::Simple.debugging?
      return ((not @__transaction_checkpoint__.nil?) and @__transaction_names__.include?(name))
    end
  end

  # Returns the current name of the transaction. Transactions not explicitly
  # named are named +nil+.
  def transaction_name
    raise Transaction::TransactionError, Transaction::Messages[:no_transaction_open] if @__transaction_checkpoint__.nil?
    Transaction::Simple.debug_io << "#{'|' * @__transaction_level__} " << "Transaction Name: #{@__transaction_names__[-1].inspect}\n" if Transaction::Simple.debugging?
    if @__transaction_names__[-1].kind_of?(String)
      @__transaction_names__[-1].dup
    else
      @__transaction_names__[-1]
    end
  end

  # Starts a transaction. Stores the current object state. If a transaction
  # name is specified, the transaction will be named. Transaction names must
  # be unique. Transaction names of +nil+ will be treated as unnamed
  # transactions.
  def start_transaction(name = nil)
    @__transaction_level__ ||= 0
    @__transaction_names__ ||= []

    name = name.dup.freeze if name.kind_of?(String)

    raise Transaction::TransactionError, Transaction::Messages[:unique_names] if name and @__transaction_names__.include?(name)

    @__transaction_names__ << name
    @__transaction_level__ += 1

    if Transaction::Simple.debugging?
      ss = "(#{name.inspect})"
      ss = "" unless ss

      Transaction::Simple.debug_io << "#{'>' * @__transaction_level__} " << "Start Transaction#{ss}\n"
    end

    @__transaction_checkpoint__ = Marshal.dump(self)
  end

  # Rewinds the transaction. If +name+ is specified, then the intervening
  # transactions will be aborted and the named transaction will be rewound.
  # Otherwise, only the current transaction is rewound.
  #
  # After each level of transaction is rewound, if the callback method
  # #_post_transaction_rewind is defined, it will be called. It is intended
  # to allow a complex self-referential graph to fix itself. The simplest
  # way to explain this is with an example.
  #
  #   class Child
  #     attr_accessor :parent
  #   end
  #
  #   class Parent
  #     include Transaction::Simple
  #
  #     attr_reader :children
  #     def initialize
  #       @children = []
  #     end
  #
  #     def << child
  #       child.parent = self
  #       @children << child
  #     end
  #
  #     def valid?
  #       @children.all? { |child| child.parent == self }
  #     end
  #   end
  #
  #   parent = Parent.new
  #   parent << Child.new
  #   parent.start_transaction
  #   parent << Child.new
  #   parent.abort_transaction
  #   puts parent.valid? # => false
  #
  # This problem can be fixed by modifying the Parent class to include the
  # #_post_transaction_rewind callback.
  #
  #   class Parent
  #     # Reconnect the restored children to me, instead of to the bogus me
  #     # that was restored to them by Marshal::load.
  #     def _post_transaction_rewind
  #       @children.each { |child| child.parent = self }
  #     end
  #   end
  #
  #   parent = Parent.new
  #   parent << Child.new
  #   parent.start_transaction
  #   parent << Child.new
  #   parent.abort_transaction
  #   puts parent.valid? # => true
  def rewind_transaction(name = nil)
    raise Transaction::TransactionError, Transaction::Messages[:cannot_rewind_no_transaction] if @__transaction_checkpoint__.nil?

    # Check to see if we are trying to rewind a transaction that is
    # outside of the current transaction block.
    defined? @__transaction_block__ or @__transaction_block__ = nil
    if @__transaction_block__ and name
      nix = @__transaction_names__.index(name) + 1
      raise Transaction::TransactionError, Transaction::Messages[:cannot_rewind_transaction_before_block] if nix < @__transaction_block__
    end

    if name.nil?
      checkpoint = @__transaction_checkpoint__
      __rewind_this_transaction
      @__transaction_checkpoint__ = checkpoint
      ss = "" if Transaction::Simple.debugging?
    else
      raise Transaction::TransactionError, Transaction::Messages[:cannot_rewind_named_transaction] % name.inspect unless @__transaction_names__.include?(name)
      ss = "(#{name})" if Transaction::Simple.debugging?

      while @__transaction_names__[-1] != name
        @__transaction_checkpoint__ = __rewind_this_transaction
        Transaction::Simple.debug_io << "#{'|' * @__transaction_level__} " << "Rewind Transaction#{ss}\n" if Transaction::Simple.debugging?
        @__transaction_level__ -= 1
        @__transaction_names__.pop
      end
      checkpoint = @__transaction_checkpoint__
      __rewind_this_transaction
      @__transaction_checkpoint__ = checkpoint
    end
    Transaction::Simple.debug_io << "#{'|' * @__transaction_level__} " << "Rewind Transaction#{ss}\n" if Transaction::Simple.debugging?
    self
  end

  # Aborts the transaction. Rewinds the object state to what it was before
  # the transaction was started and closes the transaction. If +name+ is
  # specified, then the intervening transactions and the named transaction
  # will be aborted. Otherwise, only the current transaction is aborted.
  #
  # See #rewind_transaction for information about dealing with complex
  # self-referential object graphs.
  #
  # If the current or named transaction has been started by a block
  # (Transaction::Simple.start), then the execution of the block will be
  # halted with +break+ +self+.
  def abort_transaction(name = nil)
    raise Transaction::TransactionError, Transaction::Messages[:cannot_abort_no_transaction] if @__transaction_checkpoint__.nil?

    # Check to see if we are trying to abort a transaction that is outside
    # of the current transaction block. Otherwise, raise TransactionAborted
    # if they are the same.
    defined? @__transaction_block__ or @__transaction_block__ = nil
    if @__transaction_block__ and name
      nix = @__transaction_names__.index(name) + 1
      raise Transaction::TransactionError, Transaction::Messages[:cannot_abort_transaction_before_block] if nix < @__transaction_block__

      raise Transaction::TransactionAborted if @__transaction_block__ == nix
    end

    raise Transaction::TransactionAborted if @__transaction_block__ == @__transaction_level__

    if name.nil?
      __abort_transaction(name)
    else
      raise Transaction::TransactionError, Transaction::Messages[:cannot_abort_named_transaction] % name.inspect unless @__transaction_names__.include?(name)
      __abort_transaction(name) while @__transaction_names__.include?(name)
    end

    self
  end

  # If +name+ is +nil+ (default), the current transaction level is closed
  # out and the changes are committed.
  #
  # If +name+ is specified and +name+ is in the list of named transactions,
  # then all transactions are closed and committed until the named
  # transaction is reached.
  def commit_transaction(name = nil)
    raise Transaction::TransactionError, Transaction::Messages[:cannot_commit_no_transaction] if @__transaction_checkpoint__.nil?
    @__transaction_block__ ||= nil

    # Check to see if we are trying to commit a transaction that is outside
    # of the current transaction block. Otherwise, raise
    # TransactionCommitted if they are the same.
    if @__transaction_block__ and name
      nix = @__transaction_names__.index(name) + 1
      raise Transaction::TransactionError, Transaction::Messages[:cannot_commit_transaction_before_block] if nix < @__transaction_block__

      raise Transaction::TransactionCommitted if @__transaction_block__ == nix
    end

    raise Transaction::TransactionCommitted if @__transaction_block__ == @__transaction_level__

    if name.nil?
      ss = "" if Transaction::Simple.debugging?
      __commit_transaction
      Transaction::Simple.debug_io << "#{'<' * @__transaction_level__} " << "Commit Transaction#{ss}\n" if Transaction::Simple.debugging?
    else
      raise Transaction::TransactionError, Transaction::Messages[:cannot_commit_named_transaction] % name.inspect unless @__transaction_names__.include?(name)
      ss = "(#{name})" if Transaction::Simple.debugging?

      while @__transaction_names__[-1] != name
        Transaction::Simple.debug_io << "#{'<' * @__transaction_level__} " << "Commit Transaction#{ss}\n" if Transaction::Simple.debugging?
        __commit_transaction
      end
      Transaction::Simple.debug_io << "#{'<' * @__transaction_level__} " << "Commit Transaction#{ss}\n" if Transaction::Simple.debugging?
      __commit_transaction
    end

    self
  end

  # Alternative method for calling the transaction methods. An optional name
  # can be specified for named transaction support. This method is
  # deprecated and will be removed in Transaction::Simple 2.0.
  #
  # #transaction(:start)::  #start_transaction
  # #transaction(:rewind):: #rewind_transaction
  # #transaction(:abort)::  #abort_transaction
  # #transaction(:commit):: #commit_transaction
  # #transaction(:name)::   #transaction_name
  # #transaction::          #transaction_open?
  def transaction(action = nil, name = nil)
    _method = case action
              when :start then :start_transaction
              when :rewind then :rewind_transaction
              when :abort then :abort_transaction
              when :commit then :commit_transaction
              when :name then :transaction_name
              when nil then :transaction_open?
              else nil
              end

    if method
      warn "The #transaction method has been deprecated. Use #{method} instead."
    else
      warn "The #transaction method has been deprecated."
    end

    case method
    when :transaction_name
      __send__ method
    when nil
      nil
    else
      __send__ method, name
    end
  end

  # Allows specific variables to be excluded from transaction support. Must
  # be done after extending the object but before starting the first
  # transaction on the object.
  #
  #   vv.transaction_exclusions << "@io"
  def transaction_exclusions
    @transaction_exclusions ||= []
  end

  class << self
    def __common_start(name, vars, &block)
      raise Transaction::TransactionError, Transaction::Messages[:cannot_start_empty_block_transaction] if vars.empty?

      if block
        begin
          vlevel = {}

          vars.each do |vv|
            vv.extend(Transaction::Simple)
            vv.start_transaction(name)
            vlevel[vv.__id__] = vv.instance_variable_get(:@__transaction_level__)
            vv.instance_variable_set(:@__transaction_block__, vlevel[vv.__id__])
          end

          yield(*vars)
        rescue Transaction::TransactionAborted
          vars.each do |vv|
            if name.nil? and vv.transaction_open?
              loop do
                tlevel = vv.instance_variable_get(:@__transaction_level__) || -1
                vv.instance_variable_set(:@__transaction_block__, -1)
                break if tlevel < vlevel[vv.__id__]
                vv.abort_transaction if vv.transaction_open?
              end
            elsif vv.transaction_open?(name)
              vv.instance_variable_set(:@__transaction_block__, -1)
              vv.abort_transaction(name)
            end
          end
        rescue Transaction::TransactionCommitted
          nil
        ensure
          vars.each do |vv|
            if name.nil? and vv.transaction_open?
              loop do
                tlevel = vv.instance_variable_get(:@__transaction_level__) || -1
                break if tlevel < vlevel[vv.__id__]
                vv.instance_variable_set(:@__transaction_block__, -1)
                vv.commit_transaction if vv.transaction_open?
              end
            elsif vv.transaction_open?(name)
              vv.instance_variable_set(:@__transaction_block__, -1)
              vv.commit_transaction(name)
            end
          end
        end
      else
        vars.each do |vv|
          vv.extend(Transaction::Simple)
          vv.start_transaction(name)
        end
      end
    end
    private :__common_start

    # Start a named transaction in a block. The transaction will auto-commit
    # when the block finishes.
    def start_named(name, *vars, &block)
      __common_start(name, vars, &block)
    end

    # Start a named transaction in a block. The transaction will auto-commit
    # when the block finishes.
    def start(*vars, &block)
      __common_start(nil, vars, &block)
    end
  end

  def __abort_transaction(name = nil) #:nodoc:
    @__transaction_checkpoint__ = __rewind_this_transaction

    if Transaction::Simple.debugging?
      if name.nil?
        ss = ""
      else
        ss = "(#{name.inspect})"
      end

      Transaction::Simple.debug_io << "#{'<' * @__transaction_level__} " << "Abort Transaction#{ss}\n"
    end

    @__transaction_level__ -= 1
    @__transaction_names__.pop
    if @__transaction_level__ < 1
      @__transaction_level__ = 0
      @__transaction_names__ = []
      @__transaction_checkpoint__ = nil
    end
  end

  SKIP_TRANSACTION_VARS = %w(@__transaction_checkpoint__ @__transaction_level__)

  def __rewind_this_transaction #:nodoc:
    defined? @__transaction_checkpoint__ or @__transaction_checkpoint__ = nil
    raise Transaction::TransactionError, Transaction::Messages[:cannot_rewind_no_transaction] if @__transaction_checkpoint__.nil?
    rr = Marshal.restore(@__transaction_checkpoint__)

    replace(rr) if respond_to?(:replace)

    iv = rr.instance_variables - SKIP_TRANSACTION_VARS - self.transaction_exclusions
    iv.each do |vv|
      next if self.transaction_exclusions.include?(vv)

      instance_variable_set(vv, rr.instance_variable_get(vv))
    end

    rest = instance_variables - rr.instance_variables - SKIP_TRANSACTION_VARS - self.transaction_exclusions
    rest.each do |vv|
      remove_instance_variable(vv)
    end

    _post_transaction_rewind if respond_to?(:_post_transaction_rewind)

    w, $-w = $-w, false # 20070203 OH is this very UGLY
    res = rr.instance_variable_get(:@__transaction_checkpoint__)
    $-w = w # 20070203 OH is this very UGLY
    res
  end

  def __commit_transaction #:nodoc:
    defined? @__transaction_checkpoint__ or @__transaction_checkpoint__ = nil
    raise Transaction::TransactionError, Transaction::Messages[:cannot_commit_no_transaction] if @__transaction_checkpoint__.nil?
    old = Marshal.restore(@__transaction_checkpoint__)
    w, $-w = $-w, false # 20070203 OH is this very UGLY
    @__transaction_checkpoint__ = old.instance_variable_get(:@__transaction_checkpoint__)
    $-w = w # 20070203 OH is this very UGLY

    @__transaction_level__ -= 1
    @__transaction_names__.pop

    if @__transaction_level__ < 1
      @__transaction_level__ = 0
      @__transaction_names__ = []
      @__transaction_checkpoint__ = nil
    end
  end

  private :__abort_transaction
  private :__rewind_this_transaction
  private :__commit_transaction
end
