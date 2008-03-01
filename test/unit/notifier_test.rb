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
    
    @receive_emails = read_fixtures('receive')
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
  
  def test_receive_for_site
    Notifier.receive(@receive_emails['from_jim_to_morgan_group_in_site1'].to_s)
    assert_equal 1, ActionMailer::Base.deliveries.length
    sent = ActionMailer::Base.deliveries.first
    assert_equal @receive_emails['from_jim_to_morgan_group_in_site1'].subject, sent.subject
    assert sent.body.index(@receive_emails['from_jim_to_morgan_group_in_site1'].body)
    assert_equal [people(:jim).email], sent.to
  end
  
  def test_receive_for_other_site
    Notifier.receive(@receive_emails['from_tom_to_morgan_group_in_site2'].to_s)
    assert_equal 1, ActionMailer::Base.deliveries.length
    sent = ActionMailer::Base.deliveries.first
    assert_equal @receive_emails['from_tom_to_morgan_group_in_site2'].subject, sent.subject
    assert sent.body.index(@receive_emails['from_tom_to_morgan_group_in_site2'].body)
    assert_equal [people(:tom).email], sent.to
  end
  
  def test_receive_for_wrong_site
    Notifier.receive(@receive_emails['from_jim_to_morgan_group_in_site2'].to_s)
    assert_equal 0, ActionMailer::Base.deliveries.length
  end
  
  def teardown
    Site.current = Site.find(1)
  end

  private
    def read_fixtures(action)
      emails = {}
      YAML::load(File.open("#{FIXTURES_PATH}/notifier/#{action}.yml")).each do |name, values|
        emails[name] = TMail::Mail.new
        emails[name].to = values['to']
        emails[name].from = values['from']
        emails[name].subject = values['subject']
        emails[name].body = values['body']
      end
      emails
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
