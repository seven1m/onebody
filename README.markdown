OneBody
=======

OneBody is web-based software that connects community members, especially churches, on the web.

Features
--------

* Membership Management | aka ChMS
* Online Directory | search, print
* Groups | email lists, attendance tracking
* Social Networking | friends, favorites
* Content Management System | page editing

...and more.

Up And Running
--------------

You'll first need [Ruby on Rails](http://rubyonrails.org/download),
[ImageMagick](http://www.imagemagick.org/script/index.php),
and the sqlite3-ruby gem (`sudo gem install sqlite3-ruby`). Then:

    sudo rake gems:install
    rake db:migrate
    rake onebody:new_user # or rake onebody:load_sample_data
    script/server
    # now browse to http://localhost:3000

Installation/Upgrade
--------------------

See [InstallOneBody](http://wiki.github.com/seven1m/onebody/installonebody) instructions.

If upgrading from a previous release, be sure to check the CHANGELOG for any release-specific notes/instructions.

More Information
----------------

* [Wiki](http://wiki.github.com/seven1m/onebody)
* [Blog](http://onebodyapp.wordpress.com)
* [Google Group](http://groups.google.com/group/onebodyapp)

Copyright
---------

Copyright (C) 2008-2009, [Tim Morgan](http://timmorgan.org)

Please see the license file provided with this software.