require 'mail'

Mail::Message.class_eval do
  # HACK: to make sure the email envelope is only addressed to the main recipients
  # (no cc or bcc addresses)
  # this eliminates the needless looping of group emails
  def destinations
    to_addrs
  end
end
