# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.1.6'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  
  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Include your application configuration below

require 'rubygems'
require 'RMagick'
require 'pdf/writer'
require 'open-uri'
require 'rexml/document'
require 'amazon/search'
require 'inherited_attribute'
require 'add_condition'
require 'ar_date_fix'
require 'params_tools'

ActionMailer::Base.server_settings = {
  :address  => 'localhost',
  :port  => 25,
  :domain => 'crccfamily.com',
}

YAHOO_APP_ID = 'cedar_ridge_christian_church'
AMAZON_ID = '1VQ2K3ZK8QY3001WSD82'

CHURCH_NAME = 'Cedar Ridge Christian Church'
CHURCH_OFFICE_PHONE = '(918) 254-0621'
SITE_TITLE = 'Cedar Ridge Family'
SITE_SIMPLE_URL = 'crccfamily.com'
SITE_URL = "http://#{SITE_SIMPLE_URL}/"
VISITOR_SIMPLE_URL = 'cedarridgecc.com'
VISITOR_URL = "http://www.#{VISITOR_SIMPLE_URL}/"
MONTHS = [
  ['January',  1],
  ['February',  2],
  ['March',  3],
  ['April',  4],
  ['May',  5],
  ['June',  6],
  ['July',  7],
  ['August',  8],
  ['September',  9],
  ['October',  10],
  ['November',  11],
  ['December',  12],
]
YEARS = (Date.today.year-120)..Date.today.year
PHOTO_SIZES = {
  :tn => '32x32',
  :small => '75x75',
  :medium => '150x150',
  :large => '400x400'
}
SITE_MAIL_DESCRIPTION = 'One user can send a message to another via this site. The system is monitored for abuse and allows people to contact you without getting your email address. We recommend you leave your email address private to prevent unsolicited email.'
WALL_DESCRIPTION = 'The Wall is a place for people to post friendly messages for everyone to see. The messages are not private (except that you must be signed in). Think of it like a guestbook.'
SEND_UPDATES_TO = 'seven1m@gmail.com'
BIRTHDAY_VERIFICATION_EMAIL = 'seven1m@gmail.com'
SYSTEM_NOREPLY_EMAIL = 'no-reply@crccfamily.com'
GROUP_ADDRESS_DOMAIN = 'crccfamily.com'
GROUP_LEADER_EMAIL = 'ccasey@cedarridgecc.com'
GROUP_LEADER_NAME = 'Craig Casey'
TECH_SUPPORT_CONTACT = 'Tim Morgan (tim@timmorgan.org)'
ADMIN_CHECK = Proc.new do |person|
  person.email =~ /@cedarridgecc.com$/ or (person.classes and person.classes.split(',').include?('EL')) or person.email =~ /^tim@timmorgan/
end
DAYS_NEW = 7
MAIL_GROUPS_CAN_LOG_IN = %w(M A P Y O C V)
MAIL_GROUPS_VISIBLE_BY_NON_ADMINS = MAIL_GROUPS_CAN_LOG_IN
SITE_INTRO_FOR_EMAIL = "#{SITE_TITLE} (#{SITE_URL}) is a brand new site that connects members online. The site is currently in \"beta\" -- we're testing it out and finding bugs. You're welcome to sign in too, and help us improve the system!"
HEADER_MESSAGE = "Visit <a href=\"#{VISITOR_URL}\">#{VISITOR_SIMPLE_URL}</a> for news, ministry info, sermon audio, etc."
MAX_DAILY_VERIFICATION_ATTEMPTS = 3
MOBILE_GATEWAYS = {
  'AT&T' => '%s@mobile.att.net',
  'CellularOne' => '%s@mobile.celloneusa.com',
  'Cingular' => '%s@mobile.mycingular.com',
  'Nextel' => '%s@messaging.nextel.com',
  'Sprint' => '%s@messaging.sprintpcs.com',
  'T-Mobile' => '%s@tmomail.net',
  'US Cellular' => '%s@email.uscc.net',
  'Verizon' => '%s@vtext.com',
  'Virgin Mobile' => '%s@vmobl.com',
}
BETA = true

ExceptionNotifier.exception_recipients = %w(seven1m@gmail.com)
ExceptionNotifier.sender_address =
  %("Rails App Error" <app-error@crccfamily.com>)
