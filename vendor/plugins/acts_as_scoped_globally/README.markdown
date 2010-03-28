acts\_as\_scoped\_globally
==========================

This plugin allows one to set the scope of queries on an ActiveRecord model
somewhere other than in the queries themselves.

This can be best explained with an example. For instance, in the case of
[OneBody](http://github.com/seven1m/onebody), the system was not designed
initially with multiple hosted sites in mind. Because of that, the Person,
Family, Group, and all other models were not queried from the currently selected site.

Rather than going through line after line of code, acts\_as\_scoped\_globally
was developed to modify SQL queries to include reference to a currently selected site.

Installation
------------

    script/plugin install git://github.com/seven1m/acts_as_scoped_globally.git

Setup & Usage
-------------

The model that determines scope:

    class Site < ActiveRecord::Base
      cattr_accessor :current # a place to store our currently selected site
      has_many :people
    end

The model you want to be affected:

    class Person < ActiveRecord::Base
      belongs_to :site
      acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
    end

The acts_as method takes two arguments: a foreign key and an expression to scope the records to.

    Person.find_by_email('john@example.com')
    # raises error because Site.current is not set

    # OneBody sets this in the application controller based on hostname
    Site.current = Site.find_by_host(request.host)
    # <Site id=12>

    Person.find_by_email('john@example.com')
    # SELECT * FROM people where site_id = 12 and email = 'john@example.com';

    Person.create(:email => 'tim@example.com')
    # INSERT INTO people (email, site_id) values ('tim@example.com', 12)

Bypassing the Global Scope
--------------------------

    Person.first
    # SELECT * FROM people where site_id = 12 limit 1;
  
    Person.without_global_scope do
      Person.first
      # SELECT * FROM people limit 1;
    end

Ensure Safety of the Foreign Key
--------------------------------

Be sure to either call `attr_protected FOREIGN_KEY` or to exclude the foreign key from your `attr_accessible` call on your model.
