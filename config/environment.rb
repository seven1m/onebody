# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.2.3'

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
require 'net/http'
require 'inherited_attribute'
require 'add_condition'
require 'ar_date_fix'
require 'params_tools'

ActionMailer::Base.smtp_settings = {
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
VISITOR_URL = "http://#{VISITOR_SIMPLE_URL}/"
NEWS_RSS_URL = "http://cedarridgecc.com/news/RSS" # or nil
NEWS_SIMPLE_URL = 'cedarridgecc.com/news'
NEWS_URL = "http://#{NEWS_SIMPLE_URL}/"
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
VALID_EMAIL_ADDRESS = /^[a-z\-_0-9\.]+\@[a-z\-0-9\.]+\.[a-z]{2,4}$/i
PHOTO_SIZES = {
  :tn => '32x32',
  :small => '75x75',
  :medium => '150x150',
  :large => '400x400'
}
SITE_MAIL_DESCRIPTION = 'One user can send a message to another via this site. The system is monitored for abuse and allows people to contact you without getting your email address. We recommend you leave your email address private to prevent unsolicited email.'
WALL_DESCRIPTION = 'The Wall is a place for people to post friendly messages for everyone to see. The messages are not private (except that you must be signed in). Think of it like a guestbook.'
SEND_UPDATES_TO = nil #'info@cedarridgecc.com'
CONTACT_EMAIL = 'info@cedarridgecc.com'
CONTACT_ADDRESS = '4010 West New Orleans, Broken Arrow, OK 74011-1186'
SEND_EMAIL_CHANGES_TO = 'siteadmin@cedarridgecc.com'
BIRTHDAY_VERIFICATION_EMAIL = 'siteadmin@cedarridgecc.com'
SYSTEM_NOREPLY_EMAIL = 'no-reply@crccfamily.com'
GROUP_ADDRESS_DOMAINS = ['crccfamily.com', 'crccministries.com', 'crccministries.org', 'bridgeworship.org']
GROUP_LEADER_EMAIL = 'ccasey@cedarridgecc.com'
GROUP_LEADER_NAME = 'Craig Casey'
TECH_SUPPORT_CONTACT = 'Tim Morgan (tim@timmorgan.org)'
ADMIN_CHECK = Proc.new do |person|
  person.email =~ /@cedarridgecc.com$/ or (person.classes and person.classes.split(',').include?('EL')) or person.email =~ /^tim@timmorgan/
end
DAYS_NEW = 7
MAIL_GROUPS_CAN_LOG_IN = %w(M A P Y O C V)
FLAG_CAN_LOG_IN = 'allow'
LOG_IN_CHECK = Proc.new do |person|
  MAIL_GROUPS_CAN_LOG_IN.include? person.mail_group or person.flags.to_s.include? FLAG_CAN_LOG_IN
end
MAIL_GROUPS_VISIBLE_BY_NON_ADMINS = MAIL_GROUPS_CAN_LOG_IN
FLAG_VISIBLE_BY_NON_ADMINS = FLAG_CAN_LOG_IN
SITE_INTRO_FOR_EMAIL = "#{SITE_TITLE} (#{SITE_URL}) is a brand new site that connects members online. The site is currently in \"beta\" -- we're testing it out and finding bugs. You're welcome to sign in too, and help us improve the system!"
HEADER_MESSAGE = "Visit <a href=\"#{VISITOR_URL}\">#{VISITOR_SIMPLE_URL}</a> for news, ministry info, sermon audio, etc."
ATTACHMENTS_TO_IGNORE = ['winmail.dat']
MAX_DAYS_FOR_REPLIES = 100
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
ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
  :default => "%m/%d/%Y %I:%M %p",
  :date => "%m/%d/%Y"
)

BETA = false

ExceptionNotifier.exception_recipients = %w(seven1m@gmail.com)
ExceptionNotifier.sender_address =
  %("Rails App Error" <app-error@crccfamily.com>)

# an ugly hack to convert names from legacy systems
NAME_CONVERSIONS = {
  :people => {
    25619 => {:last_name => "Mu\303\261oz"},
    31329 => {:last_name => "Mu\303\261oz"},
    31411 => {:last_name => "Mu\303\261oz"},
    24792 => {:last_name => "Mu\303\261oz"},
    32837 => {:last_name => "Mu\303\261oz"}
  },
  :families => {
    12209 => {:last_name => "Mu\303\261oz", :name => "Ed & Sherry Mu\303\261oz"},
    11564 => {:last_name => "Mu\303\261oz", :name => "Chris Mu\303\261oz"}
  }
}

ANALYTICS_CODE = <<-END_CODE
<script src="http://www.google-analytics.com/urchin.js" type="text/javascript">
</script>
<script type="text/javascript">
_uacct = "UA-1286002-2";
urchinTracker();
</script>
END_CODE

FLAG_WORDS = [/\d\d\d[\-\.]\d\d\d\d/, /\b[a-z0-9\.\-\_]{3,}@[a-z0-9\-]{3,}(\.[a-z]{2,4})+\b/i, /\binstant\sm/i, /\baddress\b/i, /\bphone\b/i, /\bmobile/i, /\baol|aim\b/i, /\.com/, /\bshit\b/i, /\bfuck/i, /\bcunt\b/i, /\bdick/i, /\bass\b/i, /\bplonker\b/i, /\bwank/i, /\bcunt/i, /\bbitch/i, /\bcock/i, /\bmotherfucker\b/i, /\bslut\b/i, /\bpussy\b/i, /\bprick\b/i, /\btits\b/i, /\bkike\b/i, /\bwop/i, /\bdaygo\b/i, /\bnigger\b/i, /\bpiss/i, /\bdego\b/i, /\basshole\b/i, /\binjun\b/i, /\bwhore\b/i, /\bhonkey\b/i, /\bcum\b/i, /\bbreasts\b/i, /\bnutsack\b/i, /\btesticles\b/i, /\bclits\b/i, /\bmasturbat/i, /\bwank/i, /\btwat\b/i, /\bgay\b/i, /\bdago\b/i, /\bc0ck\b/i, /\bfuk/i, /\bpenis\b/i, /\bteets\b/i, /\bbastard\b/i, /\btwaty\b/i, /\bassramer\b/i, /\bputa\b/i, /\bfaen\b/i, /\bhelvete\b/i, /\bhore\b/i, /\bkuk\b/i, /\bfitte\b/i, /\bkuksuger\b/i, /\bpule\b/i, /\bknulle\b/i, /\bsmut\b/i, /\bboiolas\b/i, /\bfutkretzn\b/i, /\bmuschi\b/i, /\bfag/i, /\bSchlampe\b/i, /\bVotze\b/i, /\bWichser\b/i, /\bficken\b/i, /\bfcuk\b/i, /\byed\b/i, /\bqueef/i, /\bsphencter\b/i, /\bcipa\b/i, /\bb!tch\b/i, /\bnepesaurio\b/i, /\btitties\b/i, /\bHuevon\b/i, /\bPuto\b/i, /\bFlikker\b/i, /\bsplooge\b/i, /\bFut\b/i, /\bcazzo\b/i, /\bpr0n\b/i, /\bporn\b/i, /\bfitta\b/i, /\bhui\b/i, /\bspic\b/i, /\bchink\b/i, /\bgook\b/i, /\bfeg\b/i, /\bnigga\b/i, /\bh0r\b/i, /\bfux0r\b/i, /\bshiz\b/i, /\bcawk\b/i, /\bkawk\b/i, /\bb17ch\b/i, /\bb1tch\b/i, /\bbi7ch\b/i, /\bh4x0r\b/i, /\bfatass\b/i, /\bscheiss/i, /\bKurac\b/i, /\bPicka\b/i, /\bSkribz\b/i, /\bEkto\b/i, /\bpoop\b/i, /\bfeces\b/i, /\bvittu\b/i, /\benculer\b/i, /\bkurwa\b/i, /\bdziwka\b/i, /\bspierdalaj\b/i, /\bskurwysyn\b/i, /\bfanculo\b/i, /\borospu\b/i, /\bamcik\b/i, /\brautenberg\b/i, /\bpimpis\b/i, /\bdirsa\b/i, /\bdildo\b/i, /\bpoontsee\b/i, /\barse/i, /\bkraut\b/i, /\bnazis\b/i, /\b@$$\b/i, /\bmerd\b/i, /\bpreud\b/i, /\bhoer\b/i, /\bschaffer\b/i, /\bmouliewop\b/i, /\bfanny\b/i, /\bmonkleigh\b/i, /\bqweef\b/i, /\bscrotum\b/i, /\bpreteen\b/i, /\bwhoar\b/i, /\bw00se\b/i, /\bguiena\b/i, /\bFelcher\b/i, /\bschmuck\b/i, /\blesbian\b/i, /\bforeskin\b/i, /\bbollock/i, /\bsh!t/i, /\bqueer/i, /\bnigger/i, /damn\b/i, /\bshemale\b/i, /\bklootzak\b/i, /\bhoer/i, /\bEkrem/i, /\bd4mn\b/i, /\btitty\b/i, /\bpendejo\b/i, /\bphuck\b/i, /\bcabron\b/i, /\bmerde\b/i, /\bzabourah\b/i, /\bsharmute\b/i, /\bsharmuta\b/i, /\bqaHbeh\b/i, /\bmibun\b/i, /\bmamhoon\b/i, /\bchraa\b/i, /\bayir\b/i, /\batouche\b/i, /\bpusse\b/i, /\blesbo\b/i, /\bteez\b/i, /dyke\b/i, /\bshipal\b/i, /\bmuie\b/i, /\bpizda\b/i, /\bFotze\b/i, /\bdike/i, /\bpimmel\b/i, /\bscheisse\b/i, /\bchuj\b/i, /\bpierdol/i, /\bsuka\b/i, /\bejackulate\b/i, /\bwetback/i, /\bjism\b/i, /\bjizz\b/i, /\bbutt-pirate\b/i, /\bbuceta\b/i, /\barschloch\b/i, /\bb!\+ch\b/i, /\bbi\+ch\b/i, /\bl3itch\b/i, /\bl3i\+ch\b/i, /\bandskota\b/i, /\bkanker/i]
FLAG_AGES = { # flag interactions between adults and youth
  :child => 8..15,
  :adult => 30..120
}