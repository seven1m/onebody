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

    [sudo] rake gems:install
    rake db:migrate
    rake onebody:new_user # or rake onebody:load_sample_data
    script/server # browse to http://localhost:3000

More Information
----------------

* [Wiki](http://github.com/seven1m/onebody/wikis)
* [Google Group](http://groups.google.com/group/onebodyapp)

Copyright
---------

Copyright (C) 2008-2009, [Tim Morgan](http://timmorgan.org)

Please see the license file provided with this program.
