# Mix this module into the main application module to provide
# information about the current email configuration
#
# In config/application.rb:
#
#     module OneBody
#       extend EmailConfigInfo
#     end
#
module EmailConfigInfo
  def email_configured?
    false
  end
end
