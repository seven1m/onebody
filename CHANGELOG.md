# Change Log

This is not meant to be a detailed account of everything changed in each release,
but will give a general idea of what to expect. Also included are instructions for upgrading from previous versions.

For general upgrade instructions, see the wiki
[here](https://github.com/churchio/onebody/wiki/Manual-Installation#how-to-upgrade).
Any release-specific upgrade notes below should be applied *after* the general instructions in the wiki
(unless otherwise noted).

## 3.8.0 (Unreleased)

### Changes

* Chore: Increase max file size for documents and attachments from 25mb to 75mb
* Chore: Make database text columns for messages bigger
* Feature: Setup email send/receive through Mailgun via an admin screen
* Feature: Show video player on document page when file is an mp4


## 3.7.0 (2017-03-07)

### Upgrade Notes

1.  The encoding used for string/text columns in the database has changed. The migration to update the encoding
    can take quite awhile, especially if you have a lot of data in your database. Also be sure to **make a
    backup of your database** (see https://github.com/churchio/onebody/wiki/Backups for help).

2.  Imports were not being properly scoped by site id before, and now they are. You will need to manually fix any
    imports to point to the proper site. For most people, the following should work:

    ```
    onebody console # or rails console
    [1] pry(main)> Import.unscoped.update_all('site_id = 1')
      SQL (0.7ms)  UPDATE `imports` SET site_id = 1
    => 23
    [2] pry(main)> exit
    ```

### Changes

* Chore: Upgrade to Ruby 2.3.3 and Rails to 4.2.8
* Chore: Rewrite printed directory
* Feature: Allow groups to have more than one leader
* Feature: Allow importing of custom fields
* Feature: Allow sorting directory by first, last, family name, etc.
* Feature: Record and show last signed in date on profile
* Feature: Show family avatars on profile page
* Feature: Show when the profile was created/edited
* Feature: Better custom select component (group categories, etc.)
* Feature: Generate PDF directory and present on page instead of emailing
* Feature: Only automatic redirect to profile on search if direct=true is passed
* Fix: Also show the user setup (send login invite via email) note when changing user's email
* Fix: Background image in check-in kiosk
* Fix: Eliminate N+1 query when listing imports
* Fix: Horizontal scroll on mobile with menu open
* Fix: Scope imports by site id
* Fix: Set default status to inactive
* Fix: Set people in new family to pending (check-in)
* Fix: "load more" button on timeline
* Fix: Email "inbox" script wasn't working when running as deb package
* Fix: Make mobile phone optional when signing up
* Fix: Switch atabase encoding so we now support emoji everywhere
* Fix: Layout was broken when logged in user had a really long name


## 3.6.0 (2017-02-08)

### Changes

* Chore: update Rails
* Chore: use Ruby 2.3.1
* Feature: Add Czech translation
* Feature: Add alias/known-by field
* Feature: Setting for disabling stream for homepage
* Feature: add 'Family' link to left nav bar, profile submenu
* Feature: add setting to require a password of certian length and require a strong password
* Feature: allow showing attendance for more than one group
* Feature: basic support for custom fields
* Feature: send message to subset of group (separate private message for each member selected)
* Fix: Allow more style attributes in HTML emails and don't strip formatting from emails when they are delivered
* Fix: Show correct size user photo when viewing sent message
* Fix: add validation for country code length
* Fix: admin email upon submitted changes wasn't sending
* Fix: allow some extra tags in html email
* Fix: bug getting current day for check-in
* Fix: bug with incoming email -- don't error if an email address is nil
* Fix: don't allow redirecting to other hosts
* Fix: don't collapse sidebar nav groups
* Fix: don't show map header on family page if address is hidden
* Fix: encoding errors during csv import
* Fix: incoming email from mailgun -- don't verify authenticity of post
* Fix: map tiles when on SSL
* Fix: profile update emails
* Fix: remove custom reporting feature as it had many security issues
* Fix: send individual emails for prayer requests
* Fix: show save button when changing document folder
* Fix: tab selection in Safari
* Fix: url to next page in timeline


## 3.5.0 (2016-03-19)

### Upgrade Notes

We've changed back to using `bundle install --deployment` (sorry).

### Changes

* Update UI template (AdminLTE)
* Newly redesigned CSV Import
* Experimental Debian/Ubuntu package for easier installation
* Simplify how active/inactive/pending users are classified
* Show document previews on index page
* Show friendlier message when no email server can be contacted
* Support facebook login
* Don't include deleted families in directory map
* Relax the email validation rule so emails on new TLDs can be accepted
* Update gems and config so developers can hack on OneBody on Windows
* Add 'About' section to user profile view
* Allow sorting group members and attendance list by last name
* Assign tasks to all group members
* Fix bug where prefetching email clients accidentally unsubscribe people from group emails
* Add new translations and update existing ones
* Add technical support email to help page
* Add code of conduct to project
* Allow enabling 'edit legacy id' setting
* Add multi-file upload to Documents
* Improve the Settings page
* Fix printed directory when family image is a PNG
* Fix links in emails not using https://
* Allow changing an album's visibility
* Put back email feature by default on groups
* Fix bug creating group without address
* Background and rate-limit geocoding
* Add back Gemfile.lock (it was a bad idea to remove it, sorry!)
* Update Rails to 4.2.6
* Fix attendance graphs for postgres
* Remove Docker config


## 3.4.0 (2015-03-31)

### Upgrade Notes

This is the first version that started using `bundle install` instead of `bundle install --deployment`.

To make this work, `rm -rf /var/www/onebody/vendor/bundle` and then run `bundle install` again so Rails can find the gems.

### Changes

* New check-in kiosk and printing feature
* Improve admin dashboard
* Allow document folders to be limited by group
* Allow document folders to be hidden/archived
* New Directory map feature
* Group Person stream items (timeline)
* Show "new" badges on items that are actually new
* Make background jobs thread-safe
* Show lock with tooltip on profile items that are hidden
* Upgrade to Rails 4.2
* Add experimental support for PostgreSQL as database
* Fix incoming email when using different `email_host`
* Link to prettier PDF for datetime formatting options
* Add XSendFile to provision script, fixes file downloads in AMI and OVF
* Catch sign up email errors and show helpful alert
* Ensure deleted is never null
* Ensure paperclip callbacks are run when deleting stale files
* Fix issue deleting old GeneratedFile records nightly
* Fix /session url issue when using a subfolder deployment
* Fix message link and i18n message instructions
* Fix printed directory pdf generation
* Don't allow orphaned admins
* Add ability to search for verses and then add them later.
* Search for people by group category
* Ensure email is lowercase on sign up
* Fix broken name matching in search
* Remove Gemfile.lock
* Ensure a time without a date uses today's date on attendance records
* Add setting to allow zoom level of maps diplayed on site to be configured
* Don't set Person#child if birthday year is 1900
* Use ActiveJob + sucker\_punch to export stuff and for the printable directory
* Send email in background with sucker\_punch
* Improve geocoding functionality to remove long/lats when an address does not give an accurate location.
* Switch to google geocoder for better geocoding
* Add OneBody version in header of admin dashboard with alert if not up-to-date
* Add directions to group page
* Remove extra family fields from person edit form
* Fix bug getting primary emailer
* Add checkin folders.
* Improve reordering of groups in check-in time.
* Add support for custom check-in labels.
* Add site id to documents to support multiple sites


## 3.3.0 (2015-01-18)

### Changes

* Add Reports feature
* Add new "sharable" attendance form for light-weight class check-in
* Allow sending notes with attendance/check-in submission
* New one-click installer for DigitalOcean
* Improved installation instructions on wiki
* Fix bug with international characters in site name
* Fix bug installing with wrong Ruby version
* Disable starttls in default email config
* Fix display issues when Groups feature is disabled
* Reduce ambiguity in "child/adult" selection in basic info
* Add Better Errors for development
* Fix bug showing raw data when clicking a map pin
* Clarify use of "email" field on profile edit screen
* Fix Relationships page in non-English translations
* Use https for OpenStreetMap tiles when :ssl enabled
* Add drag-and-drop upload of photos
* Upgraded Ruby version to 2.1.5.
* Upgrade to Rails 4.1.8
* Handle case when user types a random number in new verse form.
* Add setting to enable business directory


## 3.2.0 (2014-09-25)

### Upgrade Notes

* Be sure you are upgrading from a OneBody version of 3.0.0 or later. If you are upgrading from a version in the 2.x series, you will need to *first* completely upgrade to 3.0.0, *then* upgrade to this version.

* Set the Country field on all your family records:
    1. Set your "Default Country" in the admin dashboard Settings screen.
    2. Run the following rake task to set your country on all existing family records:

            RAILS_ENV=production bundle exec rake onebody:set_country

### Changes

* add Portuguese translation
* add Dutch (Netherlands) translation
* add "Country" field to people, with "Default Country" site setting
* fix bugs geocoding addresses outside the US
* add "tasks" feature for groups
* add Facebook and Twitter links to profile
* improve UX for adding a new person/family
* show a person's albums on profile page
* show family picture in search results if not profile picture
* make "small group" size configurable
* add option for groups to include all adults in the community
* improve wording in various email messages
* remove confusing "notes" feature
* add drag-and-drop sorting controls
* allow html source editing on wysiwyg editor
* add option to send prayer request as email
* add 'primary email holder' setting for family members who share an email address
* don't send rejection emails when both sender and receiving group cannot be determined
* fix bug uploading some PDF and HTML documents
* fix bug importing people by id
* fix bug printing some pages
* fix bugs with date entry and date-picker
* fix bug setting person email if no notification email is configured
* fix anniversary field showing on children
* fix bug showing/applying some profile updates
* fix bug running 'worker' with Docker
* fix bug with Google Analytics and Safari


## 3.1.1 (2014-08-18)

### Changes

* Fix bug installing in Docker


## 3.1.0 (2014-08-18)

### Changes

* Upgrade to Rails 4.1
* Improve usefulness of accounts with limited access (not full access).
* Show indicators on group pages when group is linked.
* UI bug fixes
* Fix for email addresses with newer/longer TLD
* Fix bug generating directory PDF for families missing address.
* Fix bug for users signing up when they already have an account.
* Fix bug saving PDF as attachment.
* Fix bug adding first group member.
* Fix bug that created empty profile updates sometimes.
* Fix upload progress bar when uploading multiple images.
* Fix bug causing verification link to be invalidated in prefetching email clients.
* Improve Group browsing experience.


## 3.0.0 (2014-07-25)

### Changes

* Fix bug inserting analytics code in some cases.
* Incoming email encoding fixes.
* Fix bug accepting email from alternate email address.
* Fix synchronization from UpdateAgent.
* Improved setup experience.
* Allow admins to search by phone number or email address.
* Don't show deleted people on family page.
* Fix bug with family people ordering.
* Fix blank maps on family page.
* Save attachments on reply emails.
* Use real email address as from address whenever possible.
* Add support for MailGun for incoming and outgoing email.
* Add support for Docker.
* Fix form controls on admin attendance report.


## 3.0.0 beta 2 (2014-07-09)

### Changes

* Lots of small bug fixes following our few days in production at Cedar Ridge
* New Document Management feature for site-wide document sharing
* Refinements to the User Interface; Better profile and group pages
* Fixed bible verses to be powered by bible-api.com
* Fixes to Update Agent sync code
* Fixes for encoding problems on incoming email
* Print stylesheet so we can print attendance reports again
* Production installation instructions


## 3.0.0 beta 1 (2014-07-09)

### Changes

* Brand new User Interface
* Improved timeline feature for people profiles and groups
* Improved first-time setup experience
* All new Admin Dashboard, Settings, Profile Updates, Syncs, and other admin screens
* Improved profile, family, and group edit pages
* Prettier testimony display on profiles
* New Family page
* Improved email settings page
* Redesigned Verse listing and display pages
* Improved UI for moving a family from one family to another
* Redesigned people relationships pages
* Reorganized I18n backend for easier translation to other languages
* Suggested family name based on people in family
* Redesigned Business listing pages
* Friendlier UI for uploading photos to group, family, and person pages; now works on object creation, not just update
* Now using OpenStreetMap for maps
* Improved privacy in groups, including hiding of messages, prayer requests, photos
* Improved Prayer Request UI
* Redesigned Album and Picture pages, along with improved sharing options
* Improved Attendance entry and reports
* Improved navigation with expanding drawers to show additional links
* Added html page titles to every page for better bookmarking
* Added breadcrumb navigation
* Improved sharing buttons on home page
* New page shows who you will be sharing with based on your friends and fellow group members
* New WYSIWYG editor
* Improved data import UI
* Improved site sign-up/verification flow
* New feature notifies administrators when user changes their photo
