OneBody
=======

OneBody is web-based software that connects community members, especially churches, on the web. It runs on Ruby, Rails, and MySQL (or SQLite).

Features
--------

* Online Directory
  * ajax live search
  * save as pdf
  * business directory
* Groups
  * full email lists (incoming and outgoing emai)
  * pictures
  * prayer requests, attendance tracking
* Social Networking
  * friends
  * messaging
  * favorites
  * wall
* Membership Management
  * sync with external source
  * import, export
  * basic church management system with add, edit, delete
* Content Management System
  * visitor-facing website hosting
  * custom theme

...and more.

Test Drive
----------

You can run OneBody on SQLite and load the sample data for testing...

You'll first need [Ruby on Rails](http://rubyonrails.org/download),
[ImageMagick](http://www.imagemagick.org/script/index.php),
and the sqlite3-ruby gem (`sudo gem install sqlite3-ruby`). Then:

    sudo rake gems:install
    rake db:migrate onebody:load_sample_data
    script/server
    # visit http://localhost:3000
    # admin user: admin@example.com and password "secret"
    # normal user: user@example.com and password "secret"

See [InstallOneBody](http://wiki.github.com/seven1m/onebody/installonebody) for the full installation instructions.

More Information
----------------

* [Wiki](http://wiki.github.com/seven1m/onebody)
* [Blog](http://onebodyapp.wordpress.com)
* [Google Group](http://groups.google.com/group/onebodyapp)

Copyright
---------

Copyright (C) 2008-2009, [Tim Morgan](http://timmorgan.org)

Please see the license file provided with this software.