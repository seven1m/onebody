class CreateSettings < ActiveRecord::Migration
  def self.up
    create_table :settings do |t|
      t.string :section, :name, :limit => 100
      t.string :format, :limit => 20
      t.string :value, :text
      t.string :description, :limit => 500
      t.boolean :hidden, :default => false
      t.timestamps
    end
    [
      #section     name                           format     hidden value                                  description
      ['Name',     'Site',                        'string',  false, 'Imaginary Church Family',             'The name of the member portion of this website'],
      ['Name',     'Church',                      'string',  false, 'First Imaginary Church',              'The name of the church'],
      ['Features', 'SSL',                         'boolean', false, false,                                 "If you have SSL setup, you may turn on this feature, which will make the login page encrypted. If not, some advanced JavaScript hashing is enabled to make sure the users' passwords aren't being sent in plaintext."],
      ['Features', 'Friends',                     'boolean', false, true,                                  "Enable MySpace-style mutual friendships (confirmed via email)"],
      ['Features', 'Prayer',                      'string',  true,  nil,                                   ""                     ],
      ['Features', 'Sidebar Group Category',      'string',  false, 'Small Groups',                        "People in mutual groups of this category will be displayed on the user's profile sidebar."],
      ['Features', 'Sidebar Group Heading',       'string',  false, 'Small Group',                         'Heading to show above people in mutual groups (see above setting)'],
      ['Features', 'Banner Message',              'string',  false, nil,                                   'Message to display across top of all pages on site (HTML), like an alert'],
      ['URL',      'Site',                        'string',  false, 'http://imaginaryfamily.com/',         'URL for this site (including the trailing slash please)'],
      ['URL',      'Visitor',                     'string',  false, 'http://imaginarychurch.com',          'URL for main website (visitors will be pointed here if they happen across the member site.)'],
      ['URL',      'News',                        'string',  false, 'http://imaginarychurch.com/news',     'URL for church news (people will be pointed here for news)'],
      ['URL',      'News RSS',                    'string',  false, 'http://imaginarychurch.com/news/RSS', 'URL for church news RSS feed (news feed will be polled periodically and headlines displayed across the top of the page)'],
      ['Email',    'Host',                        'string',  false, 'localhost',                           'Hostname of your SMTP server'],
      ['Email',    'Domain',                      'string',  false, 'imaginaryfamily.com',                 'Domain name for your SMTP email server'],
      ['Services', 'Yahoo',                       'string',  false, nil,                                   'Your Yahoo API key - https://developer.yahoo.com/wsregapp/index.php'],
      ['Services', 'Amazon',                      'string',  false, nil,                                   'Your Amazon AWS Access Identifier - http://www.amazon.com/gp/browse.html?node=3435361'],
      ['Services', 'Analytics',                   'string',  false, nil,                                   'If you use Google Analytics or some other JavaScript-based stats service, put the code here. It will be inserted at the bottom of every page.'],
      ['Contact',  'Church Office Phone',         'string',  false, '(123) 456-7890',                      'Phone number for the church office'],
      ['Contact',  'Send Updates To',             'string',  false, 'admin@imaginarychurch.com',           'Email sent when someone updates their profile (can be blank for no email)'],
      ['Contact',  'Send Email Changes To',       'string',  false, 'admin@imaginarychurch.com',           'Email sent when someone changes their email address (can be blank for no email)'],
      ['Contact',  'Birthday Verification Email', 'string',  false, 'admin@imaginarychurch.com',           "Email sent when someone requests verification via birthday (shouldn't be blank)"],
      ['Contact',  'Church Email',                'string',  false, 'info@imaginarychurch.com',            'Visible in some places on site'],
      ['Contact',  'Church Address',              'string',  false, '123 West Imaginary Street, Broken Arrow, OK 12345-6789', 'Visible on Terms of Use'],
      ['Contact',  'System Noreply Email',        'string',  false, 'no-reply@imaginaryfamily.com',        'Email address where some email is sent (email that does not allow replies)'],
      ['Contact',  'Group Address Domains',       'list',    false, %w(imaginaryfamily.com imaginaryfamily.org), 'Domains to which email could be coming'],
      ['Contact',  'Tech Support Email',          'string',  false, 'morgans@somedomain.com',              'Email to contact for technical help with the site.'],
      ['Contact',  'Tech Support Contact',        'string',  false, 'Joe Schmo (joe@imaginaryhelp.com)',   'Name and email to contact for technical help with the site.'],
      ['Contact',  'Bug Notification Email',      'string',  false, nil,                                   'Email address to send bug reports to'],
      ['Access',   'Super Admins',                'list',    false, %w(morgans@somedomain.com),            'Email addresses of people who are the super admins']
    ].each do |section, name, format, hidden, value, description|
      Setting.create(:section => section, :name => name, :value => value, :format => format, :description => description, :hidden => hidden)
    end
  end

  def self.down
    drop_table :settings
  end
end