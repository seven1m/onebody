OneBody Change Log
==================

This document lists notable changes in each release, in no particular order
(though more important/sweeping changes tend to be at the top).

For detailed change history, view the Git log (http://github.com/seven1m/onebody/commits).

2.1.1 / March 20, 2011
----------------------

* Remove dependence on local RVM install for deployment.

2.1.0 / March 19, 2011
----------------------

* Parse birthday based on locale.
* Add link to edit group on group page.
* New page for group admins to see birthdays of members.
* Update gems.
* Fix schedule (crontab) and added instructions for proper RVM setup.
* Fixes for deployment recipes and newer RVM and Capistrano versions.
* Fix bug deleting group membership for deleted person.
* Fix bug deleting cached stream items on deleted people.
* Fix views failing due to deleted person.
* Fix bug saving boolean settings.
* Fix bug saving pages.
* Fix typo in photo content type.
* Fix for uploading photos with invalid type.
* Fix error when rendering error for new account.
* Fix runner call for pc\_sync background process

2.0.1 / February 8, 2011
------------------------

* Upgraded to Rails 3.0.4 to fix multiple security vulnerabilities.
* Fix bug showing help when no users are present in the db.
* Partial fix for bug syncing with PowerChurch.

2.0.0 Final / January 26, 2011
------------------------------

* Relaxed html sanitization.
* Remove tag name restrictions.
* Fix reference to wrong gemset in .rvmrc.
* Fix message creation where body is blank.
* Fix missing attachment field on group email form.
* Fix child-select field when editing a profile.
* Fix bug with birthday verification email.
* Fix bug with some auto-reply email.
* Fix group calendar bug.
* Fix attendance page appearance.
* Fix missing link to group attendance page.
* Fix handling of dates in profile updates.
* Fix all broken unit and functional tests.

2.0.0 Beta 2 / December 17, 2010
--------------------------------

* Can now edit Nav Bar color with Style Editor.
* Fix bugs in CSV import.
* Fix bugs in deployment recipes.
* Fix bugs in email handling, including group replies.
* Fix bugs in i18n.
* Fix bug preventing accounts with limited access from verifying.
* Fix bug on signup form when not all fields are completed.
* Fix email/mobile verification.
* Fix badly formatted text emails.
* Fix group admin management interface.
* Fix Sermondrop integration.
* Fix Prayer Event pages.
* Fix bugs in sync with PowerChurch.
* Improve interface for managing settings.
* Update jQuery and jQuery UI.

2.0.0 Beta 1 / December 8, 2010
-------------------------------

* Now running on Rails 3.
* Completely redesigned interface with focus on usability.
* New mobile interface with full functionality.
* New Admin Dashboard.
* Revamped Administrator management page.
* New Style Editor interface.
* Improved interface for managing profile updates.
* Easier workflow for authorizing new users.
* More efficient email handling.
* More efficient background tasks, with new background queue and worker.
* Improved caching.
* Moved all attachments to use Paperclip plugin.
* Improved Capistrano deployment recipes.
* Use RVM for deployment.
* Simplified determination of fellow group members and removed confusing "Sidebar Group" stuff.
* More efficient loading of settings for quicker startup.
* Now using SASS for stylesheets.
* Export to XML and CSV are now async background jobs.
* Page management revamp and simplification (and removal of CMS).
* Better handling of public/profile picture album creation.
* Now using jQuery and jQuery UI instead of Prototype and Scriptaculous.
* Accept mutliple file/image selections where appropriate (and in browsers that support it).
* Replace Whitelist plugin with Sanitize plugin.
* Use patched version of Rails' own default_scope rather than my old acts_as_scoped_globally plugin.

1.2.2 / October 14, 2010
------------------------

* Upgrade to Rails 2.3.10 due to security advisory CVE-2010-3933.

1.2.1 / October 13, 2010
------------------------

* New Appearance setting to show "Info" tab first on profile pages.
* New prepare:centos Capistrano recipe for installing to CentOS 5.5, with supplemental install instructions.
* Upgraded the WYSIWYG editor for news items.
* Upgraded to Rails 2.3.9.
* Fixes for existing Capistrano recipes.

1.2.0 / October 11, 2010
------------------------

**Upgrade Note:** Gem dependencies have changed. The `cap deploy` or `cap deploy:migrations` recipe will install/upgrade the dependencies, but if you are not using Capistrano for deployment, you must run `rake gems:install`.

* Change from GPL v3 to AGPL v3 license with this release (see LICENSE).
* Native sync with PowerChurch (one-way).
* New web-based first-time setup feature upon site startup.
* Updated install instructions and cap recipes. Add new prepare:ubuntu recipe.
* Prayer Event feature has returned.
* Improved mobile interface.
* Improvements to feed import feature. Removed Facebook import due problems with new FB users.
* New interface for managing group admins in one place.
* Ability to send multiple file attachments in a message via the web interface.
* Fix for email replies where the original sender address is rewritten (Calvin College, I'm looking at you).
* Fix bug causing some messages to loop around in the system unnecessarily.
* Better feedback for individuals who share an email address.
* Fixes for Google Calendar integration and timezones.
* Upgraded the WYSIWYG editor for CMS pages.
* CMS pages can now be edited as raw HTML.
* Group membership calculation is now faster.
* Content on sign up page is now customizable.
* Adult age is now configurable and defaults to 18.
* Improved formatting for the printed directory.
* New rake task for exporting SQL data for a single site.
* Deprecated SQLite support and set database.yml.example to point to MySQL.
* Improved sync with Campaign Monitor.
* Improved i18n support for Portuguese.
* Lots of little bug fixes and usebility improvements.
* More unit tests.
* Plugged some mass assignment vulnerabilities.

1.1.1 / April 11, 2010
----------------------

* Fix bug preventing group sync with Campaign Monitor.
* Fix onebody:new\_user rake task.
* Fix iPhone login form not encrypting password properly.
* Fix contributions interface for Ruby pre-1.8.7.

1.1.0 / March 29, 2010
----------------------

**Upgrade Note:** Gem dependencies have changed, so be sure to run `rake gems:install`.

* Upgrade to Rails 2.3.5.
* Beta support for I18n - English and Portuguese languages [gustavobim]
* Sync people data with Donor Tools.
* Sync group lists with Campaign Monitor.
* Integrate podcast widget from Sermondrop.
* Interface for iPhone and other mobile browsers.
* Interface for managing relationships between people.
* Improvements to the admin dashboard, including graphs.
* Sync api and interface for viewing synchronization results (UpdateAgent).
* Add changed emails interface in admin section.
* Merge "Super Admin" and standard admin interface into one.
* New Admin "Templates" feature.
* New Contributions feature, thanks to Donor Tools.
* Interface for setting a group to sync with Campaign Monitor.
* Simple Sermondrop integration.
* New group batch editing interface.
* New ability to update relationships via api.
* New authentication api.
* New option to disable removal of contact details in messages.
* Group leader is now more explicit, and selectable.
* Optional env variable for specifying site to show in dev mode.
* Limit attributes/columns that can be specified via online import method.
* Ability to reload settings from admin dashboard.
* Simplified log view; much more efficient.
* Way better handling of deleted records, and an interface to manage them.
* New plugin hook api.
* Ensure that all settings are reloaded for *all* instances of app.
* Better checks and feedback when people/group limit has been reached.
* Show 100 years at a time in the javascript date popup.
* Better counting of admins and feedback when limit is reached.
* Update Facebook feed import page.
* Clean up the group advanced tab.
* Update cap recipe to copy shared/initializers upon deploy.
* Improve performance of search by family name.
* Don't start tour upon first login.
* Fix Group calendars for Google Apps accounts.
* Fix session deletion scheduled job.
* Sort groupies by name.
* Fix icon link to add verse to favorites.
* Fix bug sending group membership requests to admins.
* Fix "stack level too deep" errors when reloading in console.
* Move setup plugin to separate project.
* Update gem dependencies for gemcutter, moved/removed gems; include minimum versions.
* Include plugin locales in I18n load path.
* Paginate all news page.
* Add rake task for finding missing keys in i18n translations.
* Clear cache when feed content is imported.
* When importing flickr photos, fallback to original size if "big" size is not found.
* Cache the last item in a feed to prevent an attempt to re-import something.
* Fix bug in log when showing pictures.
* Fix bug giving focus to search name field.
* Fix bug in album selection.
* Fix bug selecting sequence for new family members.
* Admins should not see messages in a private group.
* Don't fail on empty family search string.
* Improve nav links on attendance screen.
* Improve online import -- attempt to translate incorrect column names.
* Only import max 500 records with online import feature.
* Default log view to last 7 days.
* Added fast\_remote\_cache plugin for capistrano.
* Display the person legacy id on their profile for admins.
* Improved display of changed values in log.
* Ensure all people have a feed\_code.
* Include person legacy id in exported attendance.
* Include group link code (if any) in exported attendance.
* Add prev and next links to attendance admin.
* Delete zombie admins.
* Display the family legacy id for admins.
* Properly handle changes to Person#email and Family#barcode\_id and set/clear flags accordingly.
* Remove duplicate pages.
* Do not log changes to Person#signin\_count.
* Redefine migration rake tasks to include migrations inside plugins.
* Load settings from plugins automatically.
* Use a serialized text col to store admin privileges instead of table columns.
* Ensure removal of content within script and style tags in email.
* Don't cache settings -- causes duplicates in some cases.
* Allow to set active from new site rake task.
* Fix bug selecting all in relationships interface.

1.0.0 / October 15, 2009
------------------------

* New Debian package release.
* New virtual appliance (OVF) release.
* Ability to add/remove group memberships from profile edit page.
* Improvements to the layout of the administration section.
* New rake task for modifying settings (even hidden and global ones) from the command line.

0.9.1 / October 5, 2009
-----------------------

* Fix bug when normalizing bible verse reference.
* New Debian package building task. Needs more testing.
* Update install cap recipe to install latest Rubygems.
* Add group batch editing feature at /groups/batch.
* Fix bug getting/setting lines-based settings.
* Fix bug deleting stale pid in script/inbox.
* Expire cache when tour starts or stops.
* New admin interfaces for checkin module (separate).
* New admin interfaces for attendance.
* Initial support for Ruby 1.9.
* Hide repetitive stream items on stream page.
* Dramatic speed ups to stream page.
* Cache stream items.

0.9.0 / September 14, 2009
--------------------------

**Upgrade Note:** Database migrations have been rolled up from previous releases; you must first upgrade
to version 0.8.1 and run all database migrations before upgrading to this release.

* Upgrade to Rails 2.3.4
* New "stream" metaphor on home, profile, and group pages.
* Feed import: Facebook, Twitter, etc.
* Improved visual cues for certain interface items.
* Improved group editing interface.
* New Site Tour feature; shown upon first login.
* Link to YouVersion and eBible on verse page.
* Allow admins to remove themselves from albums and pictures.
* Add option to albums to be public or profile-only.
* Set the first uploaded pic in an album to the cover pic.
* Add feed for stream page.
* Improved wall posting feedback.
* Improved site selection from console.
* Improved email header reading/writing.
* Safeguard to prevent script/inbox from running more than one process at the same time.
* Added Yahoo map to group page.

0.8.1 / July 7, 2009
--------------------

**Upgrade Note:** Prerequisites have changed on Linux; be sure to read
[InstallOneBody](http://wiki.github.com/seven1m/onebody/installonebody).

**Upgrade Note:** Gem dependencies have changed, so be sure to run `rake gems:install`.

* Upgrade to Rails 2.3.2
* New Calendar tab with merged church-wide and group calendar events (thanks to PowerChurch)
* Ability to comment on pictures (thanks to PowerChurch)
* New "Tabbed Profile" option
* User generated News section
* Low level support for syncing a group with a Campaign Monitor subscriber list
* Feed auto-discovery for publications, friend activity, and news
* Allow HTML content in emails
* Ability to have multiple Publications groups.
* Speedups for viewing large groups
* Improved News RSS feed grabbing
* OneBody plugins are now Rails engines
* Cap recipes to install/deploy on Ruby Enterprise Edition
* Bug fixes

0.8.0 / March 7, 2009
---------------------

**Upgrade Note:** Database migrations have been rolled up from previous releases; you must first upgrade
to version 0.7.8 and run all database migrations before upgrading to this release.

**Upgrade Note:** Gem dependencies have changed, so be sure to run `rake gems:install`.

**Upgrade Note:** Scheduler has been removed. Visit
[CrontabSetup](http://wiki.github.com/seven1m/onebody/crontabsetup) for more information.

* Upgrade to Rails 2.2.2
* Add custom person fields.
* Add custom person type.
* Remove Scheduler in favor of plain old crontab.
* New custom theme editing and asset management.
* Improve performance of profile page by eliminating/consolidating sql queries and making use of MySQL indices.
* Simplify person gender to only use Male/Female/nil.
* Improve performance by storing settings in a global instead of class variable.
* Reenable caching on profile page.
* Improve performance by denormalizing blog items into separate table.
* Remove some plugins from vendor and include as gem dependencies.
* Better report following people import, including errored records and reason(s).
* Simplify profile page look.
* Improved search.
* Groups now have pictures.
* Speed up group memberships, especially linked groups and "parents-of" groups.
* New group membership privacy controls.
* Improve update submission process and interface.
* Use popup date picker for birthday and anniversary selection.
* New option to specify updates must be approved or not.
* Catch bots signing up for account using a dummy hidden field.
* New option to groups to allow users to join without requring admin approval.
* New settings to change default sharing/privacy options for new families.
* New solucija\_ib theme.
* New solucija\_im theme.
* Tons of bug fixes.

0.7.8 / October 23, 2008
------------------------

* Upgrade to Rails 2.1.2
* Add site time zone support. Add rake task to convert existing times to UTC.
* Add l10n phone and date formatting options.
* Add optional embedded Google Calendar to groups.
* Add setting to allow unencrypted logins (for mobile phones, etc.)
* Allow system and help page editing even when CMS feature is disabled.
* Do a “soft delete” on people and families.
* Ability to add existing person to a family.
* Add setting to enable/disable email relaying for people with their email addresses shared.
* Track sign in failures and lock out account/ip based on configuration setting.
* Change generic group picture to be more consistent with site design.
* Design and usability tweaks thanks to Ben Hudson.
* Show randomly-selected, limited number of “groupies” on profile with link to show all.
* Add Yahoo Map link next to profile home address (Ben Hudson).
* Populate Directory search name field from quick search box (Ben Hudson).
* Change appearance of private group.
* Show hidden people when doing a select\_person search (admins only).
* Fix friendship mirroring bug.
* Work around WYSIWYG editor escaping special syntax for inserting setting values.
* Fix bug saving family upon new account signup.
* Use male silhouette for thumbnail as fallback when gender is not set properly.
* Fix friend reordering.
* Fix bug displaying upcoming birthday icons.
* Don’t show duplicate items in the blog.
* Don’t send duplicate message to group member who received an email out of band.
* Don’t crash if friend has been deleted.
* Fix family member reordering.
* Fix log item view when showing a comment on a deleted item.
* Fix CSV import creating duplicate families; Add access/permission options to import.
* Fix add verse on existing verse.
* Fix bug showing Prayer Request in activity feed.

0.7.7 / September 26, 2008
--------------------------

* Add community logos.
* Allow “off the street” signups for certain types of communities. Sign ups can either be required to be approved by an admin or auto-approved.
* Directory can now be printed with family pictures.
* Added ACS Converter to Update Agent.
* Add legacy/external id editing to person edit form.
* How group listings are displayed
* Appearance of site header and slogan
* UpdateAgent moved to new GitHub project: seven1m/onebody-updateagent
* Group create/edit experience.
* Form feedback and textarea styling.
* Security of mass assignment in profile editing.
* Appearance of buttons and tabs.
* Reject mail from/to postmaster.
* Resize photos to 800×800 max and discard original (this will save hundreds of megabytes of disk space for sizable communities).
* Add hook to restart scheduler after a standard cap deploy.
* Ease up log flagging a bit.
* Set cap deploy.rb example config to checkout “stable” branch by default
* Update Setup mode to know about stable release vs dev release.
* Capistrano deployment recipes
* Bug sending body of email when attachment present
* Fix bug preventing people being moved to a new family.
* Fix dates of 0000-00-00 in MySQL.
* Rake newuser task should add to super admins, not overwrite it.
* Fix bug creating new site publications group.
* Fix new note ownership.
* Fix group category selection and form feedback.
* Add Publications group for new sites.
* Generate api key in onebody:api:key rake task if not present.
* Batch compare and update should take site\_id into account.
* script/inbox should not take –site arg since it is determined by Notifier#recieve anyway.
* Fix bug detecting secondary host.
* Fixed incremental search for City and State
* Fix group membership admin page
* Connector and sync script has been depreciated. Please use UpdateAgent from now on.
* UpdateAgent has been moved into its own project. Installation is only a “gem install” away.

0.7.6 / September 11, 2008
--------------------------

* Upgrade to Rails 2.1.1
* Better feedback for new account activation.
* Update Agent: overhaul for speed and efficiency
* Use BigInts for phone numbers.
* Ignore database.yml and auto-copy upon startup. Sorry, but this will likely break existing non-Capistrano installations.
* Improve Update Agent feedback and REST API efficiency.
* Bug fixes.

0.7.5 / September 3, 2008
-------------------------

* Improvements to OneBody plugin architecture.
* Start of attendance tracking for groups.
* Scheduler now reads tasks from the database rather than files with admin screen to manage scheduled tasks.
* Better contextual help for admins getting OneBody up and running.
* CMS can use a page as its template.
* REST API work, including basic authentication with API key.
* Improvements to the onebody:sites rake tasks.
* Improvements to Capistrano install and setup recipes.
* Passwords are now more securely encrypted.
* RSA encryption is used with JavaScript to provide added security when signing in and when changing user password (all without the need for SSL).
* Compression of JavaScript files to lighted bandwidth usage.
* Linked groups can now have manually added members.
* A basic REST API is now in place, along with an Update Agent script to sync your OneBody instance remotely.
* Lots of bug fixes and more regression tests.

0.7.0 / July 23, 2008
---------------------

* Content Management System - Use OneBody as your church website and your online directory.
* Split Theming - Use a different theme for your public website than for your directory, all from within the same software.
* Export of People, Family, and Group data as either XML or CSV.
* Import of People and Family data from CSV.
* OneBody plugins allow for added functionality without hacking the core system.
* Simplification of “Shares” into the “More” tab, along with easier picture uploading.
* Rewrites of nearly every controller to conform to the RESTful Resource pattern
* Tons more tests.
