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
  
  should "send group email" do
    email = to_email(:from => 'user@example.com', :to => 'college@example.com', :subject => 'test to college group from user', :body => 'Hello College Group from Jeremy.')
    Notifier.receive(email.to_s)
    assert_deliveries 2 # 2 people in college group
    assert_emails_delivered(email, groups(:college).people)
    delivery = ActionMailer::Base.deliveries.first
    assert_match /Hello College Group from Jeremy/, delivery.to_s
  end
  
  should "not send group email to group members who received the message out of band" do
    email = to_email(:from => 'user@example.com', :to => 'peter@example.com', :cc => 'college@example.com', :subject => 'test to college group from user', :body => 'Hello College Group from Jeremy.')
    Notifier.receive(email.to_s)
    assert_deliveries 1 # 2 people in college group, but only 1 should receive it (Jeremy)
    assert_emails_delivered(email, [people(:jeremy)])
    delivery = ActionMailer::Base.deliveries.first
    assert_match /Hello College Group from Jeremy/, delivery.to_s
  end
  
  should "send email update" do
    Notifier.deliver_email_update(people(:tim))
    assert !ActionMailer::Base.deliveries.empty?
    sent = ActionMailer::Base.deliveries.first
    assert_equal [Setting.get(:contact, :send_email_changes_to)], sent.to
    assert_equal "#{people(:tim).name} Changed Email", sent.subject
    assert sent.body.index("#{people(:tim).name} has had their email changed.")
    assert sent.body.index("Email: #{people(:tim).email}")
  end
  
  should "send private email and accept reply" do
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
    reply.subject = 're: test from jeremy'
    reply.body = 'hello jeremy'
    reply.in_reply_to = sent.message_id
    ActionMailer::Base.deliveries = []
    Notifier.receive(reply.to_s)
    assert_equal 1, ActionMailer::Base.deliveries.length
    sent = ActionMailer::Base.deliveries.first
    assert_equal [people(:jeremy).email], sent.to
    assert_equal 're: test from jeremy', sent.subject
    assert sent.from != people(:jennie).email
    assert sent.body.index("hello jeremy")
  end
  
  should "send private email and accept reply from outlook" do
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
    reply.subject = 're: test from jeremy'
    reply.body = "hello jeremy\n" + sent.body
    ActionMailer::Base.deliveries = []
    Notifier.receive(reply.to_s)
    assert_equal 1, ActionMailer::Base.deliveries.length
    sent = ActionMailer::Base.deliveries.first
    assert_equal [people(:jeremy).email], sent.to
    assert_equal 're: test from jeremy', sent.subject
    assert sent.from != people(:jennie).email
    assert sent.body.index("hello jeremy")
  end 
  
  should "reject unsolicited email" do
    msg = TMail::Mail.new
    msg.from = "Jennie Morgan <#{people(:jennie).email}>"
    msg.to = 'jeremysmith@example.com'
    msg.subject = 'hi jeremy'
    msg.body = 'hello jeremy'
    Notifier.receive(msg.to_s)
    assert_equal 1, ActionMailer::Base.deliveries.length
    sent = ActionMailer::Base.deliveries.first
    assert_equal [people(:jennie).email], sent.to
    assert_equal 'Message Rejected', sent.subject
    assert_equal [Site.current.noreply_email], sent.from
    assert sent.body.index("unsolicited")
  end
  
  should "reject email from unknown sender" do
    msg = TMail::Mail.new
    msg.from = "Joe Spammer <joe@spammy.com>"
    msg.to = 'jeremysmith@example.com'
    msg.subject = 'hi jeremy'
    msg.body = 'hello jeremy'
    Notifier.receive(msg.to_s)
    assert_equal 1, ActionMailer::Base.deliveries.length
    sent = ActionMailer::Base.deliveries.first
    assert_equal ['joe@spammy.com'], sent.to
    assert_equal 'Message Rejected', sent.subject
    assert_equal [Site.current.noreply_email], sent.from
    assert sent.body.index("the system does not recognize your email address")
  end
  
  should "accept multipart email with attachment" do
    Notifier.receive(File.read(File.join(FIXTURES_PATH, 'multipart.email')))
    assert_equal 2, ActionMailer::Base.deliveries.length
    assert message = Message.find(:first, :order => 'id desc')
    assert_equal 'multipart test', message.subject
    assert_match /This is a test of complicated multipart message/, message.body
    assert_equal 1, message.attachments.count
    delivery = ActionMailer::Base.deliveries.first
    assert_match /This is a test of complicated multipart message/, delivery.to_s
  end
  
  should "discard email sent to the noreply address" do
    msg = TMail::Mail.new
    msg.from = "Jennie Morgan <#{people(:jennie).email}>" # even from known address
    msg.to = Site.current.noreply_email
    msg.subject = 're: hi jeremy'
    msg.body = 'some sort of automated response'
    Notifier.receive(msg.to_s)
    assert_equal 0, ActionMailer::Base.deliveries.length
  end
  
  should "receive email for different sites" do
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
  
  should "reject email for the wrong site" do
    email = to_email(:from => 'jim@example.com', :to => 'morgan@site2', :subject => 'test to morgan group in site 2 (should fail)', :body => 'Hello Site 2 from Tom! This should fail.')
    Notifier.receive(email.to_s)
    assert_deliveries 1
    sent = ActionMailer::Base.deliveries.first
    assert_equal email.from, sent.to
    assert_equal 'Message Rejected', sent.subject
    assert_equal [Site.current.noreply_email], sent.from
    assert sent.body.index("the system does not recognize your email address")
  end
  
  def teardown
    Site.current = Site.find(1)
  end

  private
    def to_email(values)
      values.symbolize_keys!
      email = TMail::Mail.new
      email.to = values[:to]
      email.cc = values[:cc] if values[:cc]
      email.from = values[:from]
      email.subject = values[:subject]
      email.body = values[:body]
      email
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
