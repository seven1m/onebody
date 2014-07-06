# OneBody

[![Build Status](https://travis-ci.org/churchio/onebody.png)](https://travis-ci.org/churchio/onebody)

OneBody is open-source, web-based social networking and online directory software for churches. OneBody is built on Ruby 2.1.2, Rails 4.0 and MySQL.

## Development Setup using Vagrant

1. Install [Vagrant](http://docs.vagrantup.com/v2/installation/index.html).
2. `git clone git://github.com/churchio/onebody.git && cd onebody`
3. `vagrant up`

Now visit the site running in development mode at localhost:8080

Whenever gems are updated or new migrations are needed, you can just run `vagrant provision`.

To restart the Rails server, type `touch tmp/restart.txt`. Or you can `vagrant reload` to restart the dev box.

For more help with Vagrant, check out the [Vagrant docs](http://docs.vagrantup.com/v2/).

## Development Setup the Manual Way

1. Install Ruby 2.1.2 or higher (we recommend you use [RVM](https://rvm.io/)).
2. Install MySQL.
3. `git clone git://github.com/churchio/onebody.git && cd onebody`
4. `mysql -u root -e "create database onebody_dev default character set utf8 default collate utf8_general_ci; grant all on onebody_dev.* to onebody@localhost identified by 'onebody';"`
5. `cp config/database.yml{.example,}`
6. `bundle install`
7. `cp config/secrets.yml{.example,} && vim config/secrets.yml` - add a random secret token (you can use `rake secret` to generate a new random secret)
8. `rake db:migrate`
9. `rails server`

Now visit the site running in development mode at localhost:3000.

## Production Setup

TODO

Please visit the [PostfixEmailSetup](http://github.com/churchio/onebody/wiki/PostfixEmailSetup) page on the wiki for help with setting up incoming email.


## Tests

To run tests:

```
mysql -u root -e "create database onebody_test default character set utf8 default collate utf8_general_ci; grant all on onebody_test.* to onebody@localhost identified by 'onebody';"
rspec
```

## Get Help

* IRC channel #church.io on Freenode (try the [web-based IRC client](https://webchat.freenode.net/?channels=#church.io))
* [Wiki](http://wiki.github.com/churchio/onebody) - There is some (possibly outdated) information here. We'll work to clean this up shortly after releasing 3.0.
* [Google Group](http://groups.google.com/group/churchio) - Community of people building open source church software. If you're stuck, ask nicely for some help and you will probably get it.


## Copyright

Copyright (c) [Tim Morgan](http://timmorgan.org)

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

This software is license under the GNU Affero General Public License, version 3. See LICENSE provided with this program for the entire text.

### Design

Design is a derivative of AdminLTE, copyright (c) almasaeed2010, available [here](https://github.com/almasaeed2010/AdminLTE), licensed under MIT license. See [LICENSE](https://github.com/almasaeed2010/AdminLTE/blob/master/LICENSE).
