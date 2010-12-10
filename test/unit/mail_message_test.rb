require File.dirname(__FILE__) + '/../test_helper'

class MailMessageTest < ActiveSupport::TestCase

  should 'address envelope for "to" addresses only' do
    @message = Mail::Message.new
    @message.to      = 'tim@foo.com'
    @message.cc      = 'joe@bar.com'
    @message.bcc     = 'jil@baz.com'
    @message.subject = 'test'
    @message.body    = 'test'
    assert_equal ['tim@foo.com'], @message.destinations
  end

end
