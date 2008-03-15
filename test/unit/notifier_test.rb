require File.dirname(__FILE__) + '/../test_helper'
require 'notifier'

class NotifierTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"
  
  fixtures :people, :families

  include ActionMailer::Quoting

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
    
    #@receive_emails = read_fixtures('receive')
  end
  
  def test_email_update
    Notifier.deliver_email_update(people(:tim))
    assert !ActionMailer::Base.deliveries.empty?
    sent = ActionMailer::Base.deliveries.first
    assert_equal [Setting.get(:contact, :send_email_changes_to)], sent.to
    assert_equal "#{people(:tim).name} Changed Email", sent.subject
    assert sent.body.index("#{people(:tim).name} has had their email changed.")
    assert sent.body.index("Email: #{people(:tim).email}")
  end
  
  def test_private_email_and_reply
    Message.create :person => people(:jeremy), :to => people(:jennie), :subject => 'test from jeremy', :body => 'hello jennie'
    assert_equal 1, ActionMailer::Base.deliveries.length
    sent = ActionMailer::Base.deliveries.first
    assert_equal [people(:jennie).email], sent.to
    assert_equal "test from jeremy", sent.subject
    assert sent.from != people(:jeremy).email
    assert sent.body.index("hello jennie")
    # now reply
    reply = TMail::Mail.new
    reply.from = "Jennie Morgan <#{people(:jennie).email}>"
    reply.to = sent.from
    reply.subject = 'test reply from jennie'
    reply.body = 'hello jeremy'
    reply.in_reply_to = sent.message_id
    ActionMailer::Base.deliveries = []
    Notifier.receive(reply.to_s)
    assert_equal 1, ActionMailer::Base.deliveries.length
    sent = ActionMailer::Base.deliveries.first
    assert_equal [people(:jeremy).email], sent.to
    assert_equal "test reply from jennie", sent.subject
    assert sent.from != people(:jennie).email
    assert sent.body.index("hello jeremy")
  end
  
  def test_receive_for_different_sites
    email = to_email(:from => 'jim@example.com', :to => 'morgan@site1', :subject => 'test to morgan group in site 1', :body => 'Hello Site 1 from Jim!')
    Notifier.receive(email.to_s)
    assert_deliveries 1
    assert_emails_delivered(email, groups(:morgan_in_site_1).people)
    ActionMailer::Base.deliveries = []
    email = to_email(:from => 'tom@example.com', :to => 'morgan@site2', :subject => 'test to morgan group in site 2', :body => 'Hello Site 2 from Tom!')
    Notifier.receive(email.to_s)
    assert_deliveries 1
    assert_emails_delivered(email, groups(:morgan_in_site_2).people)
  end
  
  def test_receive_for_wrong_site
    email = to_email(:from => 'jim@example.com', :to => 'morgan@site2', :subject => 'test to morgan group in site 2 (should fail)', :body => 'Hello Site 2 from Tom! This should fail.')
    Notifier.receive(email.to_s)
    assert_deliveries 0
  end
  
  def test_receive_from_user
    email = to_email(:from => 'user@example.com', :to => 'college@example.com', :subject => 'test to college group from user', :body => 'Hello College Group from Jeremy.')
    Notifier.receive(email.to_s)
    assert_deliveries 2 # 2 people in college group
    assert_emails_delivered(email, groups(:college).people)
  end
  
  def teardown
    Site.current = Site.find(1)
  end

  private
    def to_email(values)
      values.symbolize_keys!
      email = TMail::Mail.new
      email.to = values[:to]
      email.from = values[:from]
      email.subject = values[:subject]
      email.body = values[:body]
      email
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
