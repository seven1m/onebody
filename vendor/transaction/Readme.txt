= Transaction::Simple for Ruby

Transaction::Simple provides a generic way to add active transaction
support to objects. The transaction methods added by this module will work
with most objects, excluding those that cannot be Marshal-ed (bindings,
procedure objects, IO instances, or singleton objects).

The transactions supported by Transaction::Simple are not associated with
any sort of data store. They are "live" transactions occurring in memory
on the object itself. This is to allow "test" changes to be made to an
object before making the changes permanent.

Transaction::Simple can handle an "infinite" number of transaction levels
(limited only by memory). If I open two transactions, commit the second,
but abort the first, the object will revert to the original version.

Transaction::Simple supports "named" transactions, so that multiple levels
of transactions can be committed, aborted, or rewound by referring to the
appropriate name of the transaction. Names may be any object except nil.

Transaction groups are also supported. A transaction group is an object
wrapper that manages a group of objects as if they were a single object
for the purpose of transaction management. All transactions for this group
of objects should be performed against the transaction group object, not
against individual objects in the group.

Version 1.4.0 of Transaction::Simple adds a new post-rewind hook so that
complex graph objects of the type in tests/tc_broken_graph.rb can correct
themselves.

Copyright:: Copyright (c) 2003 - 2007 by Austin Ziegler
Version::   1.4.0
Homepage::  http://rubyforge.org/projects/trans-simple/
Licence::   MIT-Style; see Licence.txt

Thanks to David Black, Mauricio Fernandez, Patrick Hurley, Pit Capitain, and
Matz for their assistance with this library.

== Usage
  include 'transaction/simple'

  v = "Hello, you."               # -> "Hello, you."
  v.extend(Transaction::Simple)   # -> "Hello, you."

  v.start_transaction             # -> ... (a Marshal string)
  v.transaction_open?             # -> true
  v.gsub!(/you/, "world")         # -> "Hello, world."

  v.rewind_transaction            # -> "Hello, you."
  v.transaction_open?             # -> true

  v.gsub!(/you/, "HAL")           # -> "Hello, HAL."
  v.abort_transaction             # -> "Hello, you."
  v.transaction_open?             # -> false

  v.start_transaction             # -> ... (a Marshal string)
  v.start_transaction             # -> ... (a Marshal string)

  v.transaction_open?             # -> true
  v.gsub!(/you/, "HAL")           # -> "Hello, HAL."

  v.commit_transaction            # -> "Hello, HAL."
  v.transaction_open?             # -> true
  v.abort_transaction             # -> "Hello, you."
  v.transaction_open?             # -> false

== Named Transaction Usage
  v = "Hello, you."               # -> "Hello, you."
  v.extend(Transaction::Simple)   # -> "Hello, you."

  v.start_transaction(:first)     # -> ... (a Marshal string)
  v.transaction_open?             # -> true
  v.transaction_open?(:first)     # -> true
  v.transaction_open?(:second)    # -> false
  v.gsub!(/you/, "world")         # -> "Hello, world."

  v.start_transaction(:second)    # -> ... (a Marshal string)
  v.gsub!(/world/, "HAL")         # -> "Hello, HAL."
  v.rewind_transaction(:first)    # -> "Hello, you."
  v.transaction_open?             # -> true
  v.transaction_open?(:first)     # -> true
  v.transaction_open?(:second)    # -> false

  v.gsub!(/you/, "world")         # -> "Hello, world."
  v.start_transaction(:second)    # -> ... (a Marshal string)
  v.gsub!(/world/, "HAL")         # -> "Hello, HAL."
  v.transaction_name              # -> :second
  v.abort_transaction(:first)     # -> "Hello, you."
  v.transaction_open?             # -> false

  v.start_transaction(:first)     # -> ... (a Marshal string)
  v.gsub!(/you/, "world")         # -> "Hello, world."
  v.start_transaction(:second)    # -> ... (a Marshal string)
  v.gsub!(/world/, "HAL")         # -> "Hello, HAL."

  v.commit_transaction(:first)    # -> "Hello, HAL."
  v.transaction_open?             # -> false

== Block Transaction Usage
  v = "Hello, you."               # -> "Hello, you."
  Transaction::Simple.start(v) do |tv|
      # v has been extended with Transaction::Simple and an unnamed
      # transaction has been started.
    tv.transaction_open?          # -> true
    tv.gsub!(/you/, "world")      # -> "Hello, world."

    tv.rewind_transaction         # -> "Hello, you."
    tv.transaction_open?          # -> true

    tv.gsub!(/you/, "HAL")        # -> "Hello, HAL."
      # The following breaks out of the transaction block after
      # aborting the transaction.
    tv.abort_transaction          # -> "Hello, you."
  end
    # v still has Transaction::Simple applied from here on out.
  v.transaction_open?             # -> false

  Transaction::Simple.start(v) do |tv|
    tv.start_transaction          # -> ... (a Marshal string)

    tv.transaction_open?          # -> true
    tv.gsub!(/you/, "HAL")        # -> "Hello, HAL."

      # If #commit_transaction were called without having started a
      # second transaction, then it would break out of the transaction
      # block after committing the transaction.
    tv.commit_transaction         # -> "Hello, HAL."
    tv.transaction_open?          # -> true
    tv.abort_transaction          # -> "Hello, you."
  end
  v.transaction_open?             # -> false

== Transaction Groups
  require 'transaction/simple/group'

  x = "Hello, you."
  y = "And you, too."

  g = Transaction::Simple::Group.new(x, y)
  g.start_transaction(:first)     # -> [ x, y ]
  g.transaction_open?(:first)     # -> true
  x.transaction_open?(:first)     # -> true
  y.transaction_open?(:first)     # -> true

  x.gsub!(/you/, "world")         # -> "Hello, world."
  y.gsub!(/you/, "me")            # -> "And me, too."

  g.start_transaction(:second)    # -> [ x, y ]
  x.gsub!(/world/, "HAL")         # -> "Hello, HAL."
  y.gsub!(/me/, "Dave")           # -> "And Dave, too."

  g.rewind_transaction(:second)   # -> [ x, y ]
  x                               # -> "Hello, world."
  y                               # -> "And me, too."

  x.gsub!(/world/, "HAL")         # -> "Hello, HAL."
  y.gsub!(/me/, "Dave")           # -> "And Dave, too."

  g.commit_transaction(:second)   # -> [ x, y ]
  x                               # -> "Hello, HAL."
  y                               # -> "And Dave, too."

  g.abort_transaction(:first)     # -> [ x, y ]
  x                               = -> "Hello, you."
  y                               = -> "And you, too."

== Thread Safety
Threadsafe versions of Transaction::Simple and Transaction::Simple::Group
exist; these are loaded from 'transaction/simple/threadsafe' and
'transaction/simple/threadsafe/group', respectively, and are represented in
Ruby code as Transaction::Simple::ThreadSafe and
Transaction::Simple::ThreadSafe::Group, respectively.

== Contraindications
While Transaction::Simple is very useful, it has limitations that must be
understood prior to using it. Transaction::Simple:

* uses Marshal. Thus, any object which cannot be Marshal-ed cannot use
  Transaction::Simple. In my experience, this affects singleton objects
  more often than any other object.
* does not manage external resources. Resources external to the object and
  its instance variables are not managed at all. However, all instance
  variables and objects "belonging" to those instance variables are
  managed. If there are object reference counts to be handled,
  Transaction::Simple will probably cause problems.
* is not thread-safe. In the ACID ("atomic, consistent, isolated,
  durable") test, Transaction::Simple provides consistency and durability, but
  cannot itself provide isolation. Transactions should be considered "critical
  sections" in multi-threaded applications. Thread safety of the transaction
  acquisition and release process itself can be ensured with the thread-safe
  version, Transaction::Simple::ThreadSafe. With transaction groups, some
  level of atomicity is assured.
* does not maintain Object#__id__ values on rewind or abort. This only affects
  complex self-referential graphs. tests/tc_broken_graph.rb demonstrates this
  and its mitigation with the new post-rewind hook. #_post_transaction_rewind.
  Matz has implemented an experimental feature in Ruby 1.9 that may find its
  way into the released Ruby 1.9.1 and ultimately Ruby 2.0 that would obviate
  the need for #_post_transaction_rewind. Pit Capitain has also suggested a
  workaround that does not require changes to core Ruby, but does not work in
  all cases. A final resolution is still pending further discussion.
* Can be a memory hog if you use many levels of transactions on many
  objects.

$Id: Readme.txt 50 2007-02-03 20:26:19Z austin $
