# Name
CHURCH_NAME = 'Cedar Ridge Christian Church'
SITE_TITLE = 'Cedar Ridge Family'

# URLs
SITE_SIMPLE_URL = 'crccfamily.com'
SITE_URL = "http://#{SITE_SIMPLE_URL}/"
VISITOR_SIMPLE_URL = 'cedarridgecc.com'
VISITOR_URL = "http://#{VISITOR_SIMPLE_URL}/"
NEWS_RSS_URL = "http://cedarridgecc.com/news/RSS" # or nil
NEWS_SIMPLE_URL = 'cedarridgecc.com/news'
NEWS_URL = "http://#{NEWS_SIMPLE_URL}/"

# Email
MAIL_HOST = 'localhost'
MAIL_DOMAIN = 'crccfamily.com'

# Services
YAHOO_APP_ID = 'cedar_ridge_christian_church'
AMAZON_ID = '1VQ2K3ZK8QY3001WSD82'

# Contact
CHURCH_OFFICE_PHONE = '(918) 254-0621'
SEND_UPDATES_TO = nil #'info@cedarridgecc.com'
CONTACT_EMAIL = 'info@cedarridgecc.com'
CONTACT_ADDRESS = '4010 West New Orleans, Broken Arrow, OK 74011-1186'
SEND_EMAIL_CHANGES_TO = 'siteadmin@cedarridgecc.com'
BIRTHDAY_VERIFICATION_EMAIL = 'siteadmin@cedarridgecc.com'
SYSTEM_NOREPLY_EMAIL = 'no-reply@crccfamily.com'
GROUP_ADDRESS_DOMAINS = ['crccfamily.com', 'crccministries.com', 'crccministries.org', 'bridgeworship.org']
GROUP_LEADER_EMAIL = 'ccasey@cedarridgecc.com'
GROUP_LEADER_NAME = 'Craig Casey'
TECH_SUPPORT_EMAIL = 'tim@timmorgan.org'
TECH_SUPPORT_CONTACT = "Tim Morgan (#{TECH_SUPPORT_EMAIL})"

# Site Accounts
STAFF_CHECK = Proc.new do |person|
  person.email =~ /@cedarridgecc.com$/ or (person.classes and person.classes.split(',').include?('EL'))
end
MAIL_GROUPS_CAN_LOG_IN = %w(M A P Y O C V)
FLAG_CAN_LOG_IN = 'allow'
MEMBER_MAIL_GROUPS = %w(M)
FULL_ACCESS_MAIL_GROUPS = %w(M A C)
MAIL_GROUPS_VISIBLE_BY_NON_ADMINS = MAIL_GROUPS_CAN_LOG_IN
FLAG_VISIBLE_BY_NON_ADMINS = FLAG_CAN_LOG_IN
SUPER_ADMINS = %w(morgans@somedomain.com) # by email address

# Stat Tracking
ANALYTICS_CODE = <<-END_CODE
<script src="https://ssl.google-analytics.com/urchin.js" type="text/javascript">
</script>
<script type="text/javascript">
_uacct = "UA-1286002-2";
urchinTracker();
</script>
END_CODE

# Bug Notification
BUG_NOTIFICATION_EMAIL = TECH_SUPPORT_EMAIL # set to nil to turn off notifications