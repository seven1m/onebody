# OneBody

[![Build Status](https://travis-ci.org/churchio/onebody.png)](https://travis-ci.org/churchio/onebody)

**WARNING: This is the 'next' branch, where some heavy-duty refactoring is going on. This branch is most likely broken right now (you can follow work progress [here](https://github.com/churchio/onebody/issues/milestones)). Be sure to `git checkout master` if you want the old stable OneBody.**

OneBody is open-source, web-based social networking and online directory software for churches. OneBody is built on Ruby 1.9.3, Rails 3.2 and MySQL.


## Setup

1. Install Ruby 1.9.3 or higher (we recommend you use [RVM](https://rvm.io/)).
2. Install MySQL.
3. `git clone git://github.com/seven1m/onebody.git`
4. `mysql -u root -e "create database onebody_dev; grant all on onebody_dev.* to onebody@localhost identified by 'onebody';"`
5. `cd onebody && bundle install && rake db:migrate`
6. `rails server`

Now visit the site running in development mode at localhost:3000.

We also have full step-by-step instructions in our INSTALL.md file.

Please visit the [PostfixEmailSetup](http://github.com/seven1m/onebody/wiki/PostfixEmailSetup) page on the wiki for help with setting up incoming email.


## Get Help

* [Wiki](http://wiki.github.com/seven1m/onebody) - A wonderful resource full of helpful information; Check here first.
* [Google Group](http://groups.google.com/group/churchio) - Community of people building open source church software. If you're stuck, ask nicely for some help and you will probably get it.


## Copyright

Copyright (c) 2008-2013, [Tim Morgan](http://timmorgan.org)

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

This software is license under the GNU Affero General Public License, version 3. See LICENSE provided with this program for the entire text.
