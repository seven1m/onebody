attr_accessible_if
==================

This Rails plugin overwrites the standard ActiveRecord attr_accessible class method to allow for an options hash. You can specify the following options:

**:if**
Pass in a Proc that will be executed to determine if the list of attributes should be accessible or not at run-time 

This is the only option available at the moment.

Installation
------------

    script/plugin install git://github.com/seven1m/attr_accessible_if.git

Example
-------

    # model
    class Person < ActiveRecord::Base
      attr_accessible :admin, :if => Proc.new { Person.logged_in.admin? }
    end

Notice our Proc is referencing a class attribute to determine the current logged in user. This is because we're operating at the model level, and no controller instance variables are available. To accomplish this, you could do something like the following:

    # model
    class Person < ActiveRecord::Base
      cattr_accessor :logged_in
    end
    
    # controller
    class ApplicationController < ActionController::Base
      before_filter :set_logged_in_user
      
      private
        def set_logged_in_user
          Person.logged_in = @logged_in = authenticate_user()
        end
    end

Copyright (c) 2010 Tim Morgan, released under the MIT license
