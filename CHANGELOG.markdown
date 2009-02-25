OneBody Changelog
=================

0.8.0 / March, 2009
-------------------

**Upgrade Note:** Database migrations have been rolled up from previous releases; you must first upgrade
to version 0.7.8 and run all database migrations before upgrading to this release.

**Upgrade Note:** Gem dependencies have changed, so be sure to run `rake gems:install`.

* Upgrade to Rails 2.2.2
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
* Speed up scheduler.
* Speed up group memberships, especially linked groups and "parents-of" groups.
* New group membership privacy controls.
* Improve update submission process and interface.
* Use popup date picker for birthday and anniversary selection.
* New option to specify updates must be approved or not.
* Catch bots signing up for account using a dummy hidden field.
* New option to groups to allow users to join without requring admin approval.
* New settings to change default sharing/privacy options for new families.
* New solucija_ib theme.
* New solucija_im theme.
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
* Show hidden people when doing a select_person search (admins only).
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
* Batch compare and update should take site_id into account.
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
