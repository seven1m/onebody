![screnshot](https://farm8.staticflickr.com/7508/15498980049_3527e0817e_b.jpg)

# OneBody

[![Install now](https://img.shields.io/badge/install-now-479de4.svg)](https://github.com/churchio/onebody/wiki/Installation)
[![Chat with us](https://img.shields.io/badge/chat-slack-e01563.svg)](http://chat.church.io)

OneBody is open-source, web-based social networking, email list, online directory, and lightweight document management software for churches.

This software has been in production use at churches for over ten years. Every feature is built by actual church members to meet the need of their own church.

Visit our website at [church.io](http://church.io) to learn more.

## Contributing to the Project

[![Build Status](https://circleci.com/gh/churchio/onebody.svg?style=svg&circle-token=efe08e5b7d161351e276a8dcf9bcb303b953c0dd)](https://circleci.com/gh/churchio/onebody)

[![Stories Ready](https://badge.waffle.io/churchio/onebody.svg?label=ready&title=stories+ready)](http://waffle.io/churchio/onebody)
[![Stories in Progress](https://badge.waffle.io/churchio/onebody.svg?label=in+progress&title=stories+in+progress)](http://waffle.io/churchio/onebody)

We ❤️ contributors! Just check out [all these people](https://github.com/orgs/churchio/people) who have helped make OneBody awesome!

To help fix a bug, first make sure it has a logged [issue](https://github.com/churchio/onebody/issues) (if not, create one), then:

1. Fork this repo on GitHub and clone your fork to your computer.
1. Set up the software on your computer by following the directions in the next section.
1. Fix the bug!
1. Submit a Pull Request to get your bug fix merged!

If you'd like to add an awesome new feature, please join our [Slack chat](https://slackin-churchio.herokuapp.com/) to talk about what you want to do. We'd like to give you some guidance on approach, coding style, tests, etc.

[FAQs for Contributors](https://github.com/churchio/onebody/wiki/FAQs-for-Contributors) ·
[Code of Conduct](https://github.com/churchio/onebody/blob/master/CONDUCT.md)

### Development Setup Using Vagrant

If you're a developer and want to get everything running locally, this is the easiest way.

Operating System: Windows, Mac, or Linux

1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads). It's free and it runs on Windows, Mac, and Linux.
1. Install [Vagrant](http://www.vagrantup.com/downloads) on your host machine.
1. Install [Git](http://git-scm.com/downloads).
   * If you're on Mac, you can use [GitHub for Mac](https://mac.github.com/).
   * If you're on Windows, you can use [GitHub for Windows](https://windows.github.com/).
1. Clone the repository to your host machine: `git clone git://github.com/churchio/onebody.git` (If you forked the project, clone from your own fork.)
1. In your terminal, change to the project directory: `cd onebody`
1. Run vagrant: `vagrant up`

Now visit the site running in development mode at http://localhost:8080.

You can use your favorite text editor to make changes inside the `onebody` directory. Changes should show in your browser after refreshing.

Check out [Using Vagrant](https://github.com/churchio/onebody/wiki/Using-Vagrant) on the wiki for further help and tips.

### Manual Development Setup on Mac or Linux

1. Install Ruby 2.3.3 (we recommend you use [rbenv](https://github.com/sstephenson/rbenv) or [RVM](https://rvm.io/)).
1. Install MySQL.
1. Install Git.
1. Install ImageMagick.
1. Install Node.js.
1. `git clone git://github.com/churchio/onebody.git && cd onebody`
1. `mysql -uroot -e "grant all on onebody_dev.* to onebody@localhost identified by 'onebody';"`
1. `mysql -uroot -e "grant all on onebody_test.* to onebody@localhost identified by 'onebody';"`
1. `cp config/database.yml{.mysql-example,}`
1. `gem install bundler`
1. `bundle install` (If you get an error installing eventmachine, you might need to do [this](http://stackoverflow.com/a/31516586/197498))
1. `cp config/secrets.yml{.example,} && vim config/secrets.yml` and add a random secret token to both the "development" and "test" sections (you can use `rake secret` to generate a new random secret).
1. `rake db:create db:schema:load db:seed`
1. `rails server`

Now visit the site running in development mode at http://localhost:3000.

### Manual Development Setup on Windows

1. Download the Ruby 2.3 package from http://railsinstaller.org and install.
1. Download MariaDB stable from https://downloads.mariadb.org and install. Take note of what you enter for the root password.
1. Download Git from https://git-scm.com/download/win and install.
1. Download ImageMagick from http://imagemagick.org/script/binary-releases.php#windows and install.
1. Download Node.js from https://nodejs.org/en/download/ and install.
1. Open the "Git Bash" program, then run...
1. `git clone git://github.com/churchio/onebody.git && cd onebody`
1. `mysql -uroot -pROOT_PASSWORD -e "grant all on onebody_dev.* to onebody@localhost identified by 'onebody';"`
1. `mysql -uroot -pROOT_PASSWORD -e "grant all on onebody_test.* to onebody@localhost identified by 'onebody';"`
1. `cp config/database.yml{.mysql-example,}`
1. `cp config/database.yml config/dossier.yml`
1. `gem install bundler`
1. `bundle install`
1. `cp config/secrets.yml{.example,} && vim config/secrets.yml` and add a random secret token to both the "development" and "test" sections (you can use `rake secret` to generate a new random secret).
1. `rake db:create db:schema:load db:seed`
1. `rails server`

Now visit the site running in development mode at http://localhost:3000.

### Tests

To run tests:

```
rspec
```

If you don't have a test database yet, create it like you did the dev database:

```
RAILS_ENV=test rake db:create db:schema:load
```

## Get Help

* [Slack Chat](https://slackin-churchio.herokuapp.com/)
* [Wiki](http://wiki.github.com/churchio/onebody)
* [Google Group](http://groups.google.com/group/churchio)
* [Help Guides](http://church.io/onebody/help)

## Copyright

Copyright (c) [Tim Morgan](http://timmorgan.org)

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

This software is license under the GNU Affero General Public License, version 3. See LICENSE provided with this program for the entire text.

"Church.IO" is a trademark of our federation of developers and cannot be used for promotional purposes without express written permission.

### Design

Design is a derivative of AdminLTE, copyright (c) almasaeed2010, available [here](https://github.com/almasaeed2010/AdminLTE), licensed under MIT license. See [LICENSE](https://github.com/almasaeed2010/AdminLTE/blob/master/LICENSE).
