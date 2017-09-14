require 'rails_helper'

describe Mail::Message do
  it 'should address envelope for "to" addresses only' do
    @message = Mail::Message.new
    @message.to      = 'tim@foo.com'
    @message.cc      = 'joe@bar.com'
    @message.bcc     = 'jil@baz.com'
    @message.subject = 'test'
    @message.body    = 'test'
    expect(@message.destinations).to eq(['tim@foo.com'])
  end
end
