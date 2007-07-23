# Security
# SSL is highly recommended to ensure security of users' passwords and accounts
# Once your organization has a signed SSL certificate and you have Apache set up
# to handle SSL requests, set the following value to true.
USE_SSL = false

# Name
SITE_TITLE = 'Imaginary Church Family'
CHURCH_NAME = 'First Imaginary Church'

# URLs
SITE_SIMPLE_URL = 'imaginaryfamily.com'
VISITOR_SIMPLE_URL = 'imaginarychurch.com'
NEWS_RSS_URL = "http://imaginarychurch.com/news/RSS" # or nil
NEWS_SIMPLE_URL = 'imaginarychurch.com/news' # or nil

# Email
MAIL_HOST = 'localhost'
MAIL_DOMAIN = 'imaginaryfamily.com'

# Services
# visit https://developer.yahoo.com/wsregapp/index.php to get your own key
YAHOO_APP_ID = 'YOUR_API_KEY_FROM_YAHOO'
# visit http://www.amazon.com/gp/browse.html?node=3435361, sign up, and get an AWS Access Identifier
AMAZON_ID = 'YOUR_API_KEY_FROM_AMAZON'

# Contact
CHURCH_OFFICE_PHONE = '(123) 456-7890'
SEND_UPDATES_TO = 'admin@imaginarychurch.com' # or nil -- email sent when someone updates their profile
CONTACT_EMAIL = 'info@imaginarychurch.com'
CONTACT_ADDRESS = '123 West Imaginary Street, Broken Arrow, OK 12345-6789'
SEND_EMAIL_CHANGES_TO = 'admin@imaginarychurch.com'
BIRTHDAY_VERIFICATION_EMAIL = 'admin@imaginarychurch.com'
SYSTEM_NOREPLY_EMAIL = 'no-reply@imaginaryfamily.com'
GROUP_ADDRESS_DOMAINS = ['imaginaryfamily.com', 'imaginaryfamily.org', 'imaginaryfamily.net'] # list all domains with incoming group email
TECH_SUPPORT_EMAIL = 'morgans@somedomain.com'
TECH_SUPPORT_CONTACT = "Joe Schmo (joe@imaginaryhelp.com)"

# Site Accounts
STAFF_CHECK = Proc.new do |person|
  person.email =~ /@imaginarychurch.com$/ or (person.classes and person.classes.split(',').include?('EL'))
end
MAIL_GROUPS_CAN_LOG_IN = %w(M A P Y O C V)
FLAG_CAN_LOG_IN = 'allow'
MEMBER_MAIL_GROUPS = %w(M)
FULL_ACCESS_MAIL_GROUPS = %w(M A C)
MAIL_GROUPS_VISIBLE_BY_NON_ADMINS = MAIL_GROUPS_CAN_LOG_IN
FLAG_VISIBLE_BY_NON_ADMINS = FLAG_CAN_LOG_IN
SUPER_ADMINS = %w(morgans@somedomain.com) # by email address

# Prayer Event Signup
PRAYER_EVENT = nil
# or...
# PRAYER_EVENT = ['1/21/2007 12:00', '1/29/2007 21:00']

# Stat Tracking
ANALYTICS_CODE = <<-END_CODE
  <!-- site stats code goes here -->
END_CODE

# Bug Notification
BUG_NOTIFICATION_EMAIL = TECH_SUPPORT_EMAIL # set to nil to turn off notifications

# Friends
FRIENDS_ENABLED = false