RAILS_GEM_VERSION = '1.2.3'

require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.action_controller.session_store = :active_record_store
end

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
require 'ar_schema_dumper_fix'
require 'params_tools'

require 'settings'

ActionMailer::Base.smtp_settings = {
  :address  => MAIL_HOST,
  :port  => 25,
  :domain => MAIL_DOMAIN,
}

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

DAYS_NEW = 7
MAX_DAYS_FOR_REPLIES = 100
MAX_DAILY_VERIFICATION_ATTEMPTS = 3

ATTACHMENTS_TO_IGNORE = ['winmail.dat']

FLAG_WORDS = [/\d\d\d[\-\.]\d\d\d\d/, /\b[a-z0-9\.\-\_]{3,}@[a-z0-9\-]{3,}(\.[a-z]{2,4})+\b/i, /\binstant\sm/i, /\baddress\b/i, /\bphone\b/i, /\bmobile/i, /\baol|aim\b/i, /\.com/, /\bshit\b/i, /\bfuck/i, /\bcunt\b/i, /\bdick/i, /\bass\b/i, /\bplonker\b/i, /\bwank/i, /\bcunt/i, /\bbitch/i, /\bcock/i, /\bmotherfucker\b/i, /\bslut\b/i, /\bpussy\b/i, /\bprick\b/i, /\btits\b/i, /\bkike\b/i, /\bwop/i, /\bdaygo\b/i, /\bnigger\b/i, /\bpiss/i, /\bdego\b/i, /\basshole\b/i, /\binjun\b/i, /\bwhore\b/i, /\bhonkey\b/i, /\bcum\b/i, /\bbreasts\b/i, /\bnutsack\b/i, /\btesticles\b/i, /\bclits\b/i, /\bmasturbat/i, /\bwank/i, /\btwat\b/i, /\bgay\b/i, /\bdago\b/i, /\bc0ck\b/i, /\bfuk/i, /\bpenis\b/i, /\bteets\b/i, /\bbastard\b/i, /\btwaty\b/i, /\bassramer\b/i, /\bputa\b/i, /\bfaen\b/i, /\bhelvete\b/i, /\bhore\b/i, /\bkuk\b/i, /\bfitte\b/i, /\bkuksuger\b/i, /\bpule\b/i, /\bknulle\b/i, /\bsmut\b/i, /\bboiolas\b/i, /\bfutkretzn\b/i, /\bmuschi\b/i, /\bfag/i, /\bSchlampe\b/i, /\bVotze\b/i, /\bWichser\b/i, /\bficken\b/i, /\bfcuk\b/i, /\byed\b/i, /\bqueef/i, /\bsphencter\b/i, /\bcipa\b/i, /\bb!tch\b/i, /\bnepesaurio\b/i, /\btitties\b/i, /\bHuevon\b/i, /\bPuto\b/i, /\bFlikker\b/i, /\bsplooge\b/i, /\bFut\b/i, /\bcazzo\b/i, /\bpr0n\b/i, /\bporn\b/i, /\bfitta\b/i, /\bhui\b/i, /\bspic\b/i, /\bchink\b/i, /\bgook\b/i, /\bfeg\b/i, /\bnigga\b/i, /\bh0r\b/i, /\bfux0r\b/i, /\bshiz\b/i, /\bcawk\b/i, /\bkawk\b/i, /\bb17ch\b/i, /\bb1tch\b/i, /\bbi7ch\b/i, /\bh4x0r\b/i, /\bfatass\b/i, /\bscheiss/i, /\bKurac\b/i, /\bPicka\b/i, /\bSkribz\b/i, /\bEkto\b/i, /\bpoop\b/i, /\bfeces\b/i, /\bvittu\b/i, /\benculer\b/i, /\bkurwa\b/i, /\bdziwka\b/i, /\bspierdalaj\b/i, /\bskurwysyn\b/i, /\bfanculo\b/i, /\borospu\b/i, /\bamcik\b/i, /\brautenberg\b/i, /\bpimpis\b/i, /\bdirsa\b/i, /\bdildo\b/i, /\bpoontsee\b/i, /\barse/i, /\bkraut\b/i, /\bnazis\b/i, /\b@$$\b/i, /\bmerd\b/i, /\bpreud\b/i, /\bhoer\b/i, /\bschaffer\b/i, /\bmouliewop\b/i, /\bfanny\b/i, /\bmonkleigh\b/i, /\bqweef\b/i, /\bscrotum\b/i, /\bpreteen\b/i, /\bwhoar\b/i, /\bw00se\b/i, /\bguiena\b/i, /\bFelcher\b/i, /\bschmuck\b/i, /\blesbian\b/i, /\bforeskin\b/i, /\bbollock/i, /\bsh!t/i, /\bqueer/i, /\bnigger/i, /damn\b/i, /\bshemale\b/i, /\bklootzak\b/i, /\bhoer/i, /\bEkrem/i, /\bd4mn\b/i, /\btitty\b/i, /\bpendejo\b/i, /\bphuck\b/i, /\bcabron\b/i, /\bmerde\b/i, /\bzabourah\b/i, /\bsharmute\b/i, /\bsharmuta\b/i, /\bqaHbeh\b/i, /\bmibun\b/i, /\bmamhoon\b/i, /\bchraa\b/i, /\bayir\b/i, /\batouche\b/i, /\bpusse\b/i, /\blesbo\b/i, /\bteez\b/i, /dyke\b/i, /\bshipal\b/i, /\bmuie\b/i, /\bpizda\b/i, /\bFotze\b/i, /\bdike/i, /\bpimmel\b/i, /\bscheisse\b/i, /\bchuj\b/i, /\bpierdol/i, /\bsuka\b/i, /\bejackulate\b/i, /\bwetback/i, /\bjism\b/i, /\bjizz\b/i, /\bbutt-pirate\b/i, /\bbuceta\b/i, /\barschloch\b/i, /\bb!\+ch\b/i, /\bbi\+ch\b/i, /\bl3itch\b/i, /\bl3i\+ch\b/i, /\bandskota\b/i, /\bkanker/i]
FLAG_AGES = { # flag interactions between adults and youth
  :child => 8..15,
  :adult => 30..120
}

SITE_URL = "http://#{SITE_SIMPLE_URL}/"
VISITOR_URL = "http://#{VISITOR_SIMPLE_URL}/"
NEWS_URL = "http://#{NEWS_SIMPLE_URL}/"

SITE_MAIL_DESCRIPTION = 'One user can send a message to another via this site. The system is monitored for abuse and allows people to contact you without getting your email address. We recommend you leave your email address private to prevent unsolicited email.'
WALL_DESCRIPTION = 'The Wall is a place for people to post friendly messages for everyone to see. The messages are not private (except that you must be signed in). Think of it like a guestbook.'

# Checks
LOG_IN_CHECK = Proc.new do |person|
  MAIL_GROUPS_CAN_LOG_IN.include? person.mail_group or person.flags.to_s.include? FLAG_CAN_LOG_IN
end
MEMBER_CHECK = Proc.new do |person|
  MEMBER_MAIL_GROUPS.include? person.mail_group
end
FULL_ACCESS_CHECK = Proc.new do |person|
  FULL_ACCESS_MAIL_GROUPS.include? person.mail_group or admin? or staff?
end
SUPER_ADMIN_CHECK = Proc.new do |person|
  SUPER_ADMINS.include? person.email
end

VALID_EMAIL_RE = /^[A-Z0-9\._%\-]+@[A-Z0-9\.\-]+\.[A-Z]{2,4}$/i

# Bug Notification
ExceptionNotifier.exception_recipients = [BUG_NOTIFICATION_EMAIL] if BUG_NOTIFICATION_EMAIL
ExceptionNotifier.sender_address = "\"One Body Error\" <app-error@#{MAIL_DOMAIN}>"