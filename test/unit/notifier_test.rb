require_relative '../test_helper'
require 'notifier'

class NotifierTest < ActiveSupport::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    @user = FactoryGirl.create(:person)
    @group = FactoryGirl.create(:group, address: 'group')
    @membership = @group.memberships.create!(person: @user)
  end

  context 'given 2 people in a group' do
    setup do
      @user2 = FactoryGirl.create(:person)
      @group.memberships.create!(person: @user2)
    end

    context 'given an email sent from one of the members' do
      setup do
        @email = to_email(from: @user.email, to: @group.full_address, subject: 'test to group from user', body: 'Hello Group')
        Notifier.receive(@email.to_s)
      end

      should 'delivers email to both users' do
        assert_deliveries 2
        assert_emails_delivered(@email, @group.people)
      end

      context 'given a reply from other member with original sender as TO address' do
        setup do
          body = "reply\n\n" + ActionMailer::Base.deliveries.first.body.to_s # must contain message id from original
          ActionMailer::Base.deliveries = [] # reset deliveries
          @email = to_email(from: @user2.email, to: @user.email, cc: @group.full_address, subject: 're: Hello Group', body: body)
          Notifier.receive(@email.to_s)
        end

        should 'deliver email to sender' do
          assert ActionMailer::Base.deliveries.map(&:to).flatten.include?(@user2.email)
        end

        should 'not deliver email to user who received it out-of-band' do
          assert !ActionMailer::Base.deliveries.map(&:to).flatten.include?(@user.email)
        end
      end

      context 'given a reply from other member with group address as TO address' do
        setup do
          body = "reply\n\n" + ActionMailer::Base.deliveries.first.body.to_s # must contain message id from original
          ActionMailer::Base.deliveries = [] # reset deliveries
          @email = to_email(from: @user2.email, to: @group.full_address, subject: 're: Hello Group', body: body)
          Notifier.receive(@email.to_s)
        end

        should 'deliver email to both members' do
          assert_equal [@user.email, @user2.email], ActionMailer::Base.deliveries.map(&:to).flatten.sort
        end
      end
    end
  end

  context 'two identical emails incoming' do
    # we get two copies of mail if, say, there is a group address in the "to" field
    # and an unrecognized address in the "cc" field
    # (send mail to college@example.com and cc peter@example.com)
    # The first message is properly delivered to the group
    # The second message should not try to deliver to anyone, and should not trigger a rejection notice

    setup do
      @email = to_email(from: @user.email, to: @group.full_address, cc: 'peter@example.com', subject: 'test', body: 'hello')
      Notifier.receive(@email.to_s)
      assert_emails_delivered(@email, @group.people)
      # now the second copy rolls in
      ActionMailer::Base.deliveries = []
      Notifier.receive(@email.to_s)
    end

    should 'not send rejection if previous copy of message was delivered' do
      assert_equal [], ActionMailer::Base.deliveries
    end
  end

  context 'given two people in group with same email address' do
    setup do
      @jack = FactoryGirl.create(:person, email: 'family@jackandjill.com')
      @jill = FactoryGirl.create(:person, email: 'family@jackandjill.com', family: @jack.family)
      @group.memberships.create!(person: @jack)
      @group.memberships.create!(person: @jill)
      email = to_email(from: @user.email, to: @group.full_address, subject: 'test', body: 'hello')
      Notifier.receive(email.to_s)
    end

    should 'not deliver to same email address twice' do
      assert_equal [@jack.email, @user.email], ActionMailer::Base.deliveries.map(&:to).flatten.sort
    end
  end

  context 'given invalid email address' do
    setup do
      email = to_email(from: @user.email, to: @group.full_address, subject: '')
      Notifier.receive(email.to_s)
    end

    should 'send rejection notice' do
      assert_deliveries 1
      delivery = ActionMailer::Base.deliveries.first
      assert_match @user.email, delivery.to.first
      assert_match(/too short/, delivery.to_s)
    end
  end

  should 'send email update' do
    Notifier.email_update(@user).deliver
    assert !ActionMailer::Base.deliveries.empty?
    sent = ActionMailer::Base.deliveries.first
    assert_equal [Setting.get(:contact, :send_email_changes_to)], sent.to
    assert_equal "#{@user.name} Changed Email", sent.subject
    assert sent.body.to_s.index("#{@user.name} has had their email changed.")
    assert sent.body.to_s.index("Email: #{@user.email}")
  end

  context 'given a private message between two people' do
    setup do
      @user2 = FactoryGirl.create(:person, first_name: 'Jane')
      @message = Message.create person: @user, to: @user2, subject: 'test', body: 'hello'
      @sent = ActionMailer::Base.deliveries.first
    end

    should 'deliver message' do
      assert_equal 1, ActionMailer::Base.deliveries.length
      assert_equal [@user2.email], @sent.to
      assert_equal 'test', @sent.subject
      assert_match(/^hello/, @sent.body.to_s)
    end

    should 'deliver from special address' do
      assert_equal 'johnsmith@example.com', @sent.from.first
    end

    should 'maintain message_id generated by OneBody' do
      assert_match(/<#{@message.id_and_code}_/, @sent.message_id)
    end

    context 'given a reply message' do
      setup do
        reply = Mail.new(
          from:        "#{@user2.name} <#{@user2.email}>",
          to:          @sent.from,
          subject:     're: test',
          body:        'hello!!!',
          in_reply_to: @sent.message_id
        )
        ActionMailer::Base.deliveries = []
        Notifier.receive(reply.to_s)
        @sent = ActionMailer::Base.deliveries.first
      end

      should 'deliver message' do
        assert_equal 1, ActionMailer::Base.deliveries.length
        assert_equal [@user.email], @sent.to
        assert_equal 're: test', @sent.subject
        assert_match(/^hello!!!/, @sent.body.to_s)
      end

      should 'deliver from special address' do
        assert_equal 'janesmith@example.com', @sent.from.first
      end
    end

    context 'given a reply message without in-reply-to header' do
      setup do
        reply = Mail.new(
          from:        "#{@user2.name} <#{@user2.email}>",
          to:          @sent.from,
          subject:     're: test',
          body:        'hello!!!' + @sent.body.to_s
        )
        ActionMailer::Base.deliveries = []
        Notifier.receive(reply.to_s)
      end

      should 'match message based on id in body' do
        assert_equal 2, Message.count
        assert_equal @message, Message.last.parent
      end
    end

    context 'given a reply message without any linkage to original' do
      setup do
        reply = Mail.new(
          from:        "#{@user2.name} <#{@user2.email}>",
          to:          @sent.from,
          subject:     're: test',
          body:        'hello!!!'
        )
        ActionMailer::Base.deliveries = []
        Notifier.receive(reply.to_s)
        @sent = ActionMailer::Base.deliveries.last
      end

      should 'deliver rejection notice to sender' do
        assert_equal 1, ActionMailer::Base.deliveries.length
        assert_equal [@user2.email], @sent.to
        assert_equal 'Message Rejected: re: test', @sent.subject
        assert_equal [Site.current.noreply_email], @sent.from
        assert_match(/not properly addressed/, @sent.body.to_s)
      end
    end

    context 'given a reply message with a mismatched to address' do
      setup do
        reply = Mail.new(
          from:        "#{@user2.name} <#{@user2.email}>",
          to:          'somethingelse@foo.com',
          subject:     're: test',
          body:        'hello!!!' + @sent.body.to_s,
          in_reply_to: @sent.message_id
        )
        ActionMailer::Base.deliveries = []
        Notifier.receive(reply.to_s)
      end

      should 'match message based on id in body' do
        assert_equal 2, Message.count
        assert_equal @message, Message.last.parent
      end
    end

    context 'given a reply message from an unknown sender' do
      setup do
        reply = Mail.new(
          from:        "#{@user2.name} <unknown@foo.com>",
          to:          @sent.from,
          subject:     're: test',
          body:        'hello!!!' + @sent.body.to_s,
          in_reply_to: @sent.message_id
        )
        ActionMailer::Base.deliveries = []
        Notifier.receive(reply.to_s)
        @sent = ActionMailer::Base.deliveries.last
      end

      should 'deliver rejection notice to sender' do
        assert_equal 1, ActionMailer::Base.deliveries.length
        assert_equal ['unknown@foo.com'], @sent.to
        assert_equal 'Message Rejected: re: test', @sent.subject
        assert_equal [Site.current.noreply_email], @sent.from
        assert_match(/the system does not recognize your email address/, @sent.body.to_s)
      end
    end
  end

  context 'given multipart email with attachment' do
    setup do
      raw = File.read(File.join(FIXTURES_PATH, 'multipart.email'))
      raw.gsub!(/FROM_ADDRESS/, @user.email)
      raw.gsub!(/TO_ADDRESS/, @group.full_address)
      Notifier.receive(raw)
      @message = Message.order('id desc').first
    end

    should 'save both html and text part' do
      assert_match(/This is a test of complicated multipart message/, @message.body)
      assert_match(/<p>This is a test of complicated multipart message.<\/p>/, @message.html_body)
    end

    should 'deliver the message to the group' do
      assert_equal 1, ActionMailer::Base.deliveries.length
    end

    should 'save attachment' do
      assert_equal 1, @message.attachments.count
    end
  end

  context 'email sent to the noreply address' do
    setup do
      msg = Mail.new(
        from:        @user.email,
        to:          Site.current.noreply_email,
        subject:     're: test',
        body:        'hello!!!'
      )
      Notifier.receive(msg.to_s)
    end

    should 'not deliver any messages' do
      assert_equal 0, ActionMailer::Base.deliveries.length
    end
  end

  context 'given a group in another site' do
    setup do
      @site1 = Site.current
      Site.current = @site2 = Site.create!(name: 'Site Two', host: 'two')
      @site2user = FactoryGirl.create(:person)
      @site2group = FactoryGirl.create(:group, address: 'group')
      @site2group.memberships.create!(person: @site2user)
    end

    context 'given message to group in first site' do
      setup do
        @email = to_email(from: @user.email, to: 'group@example.com', subject: 'test', body: 'hello')
        Notifier.receive(@email.to_s)
      end

      should 'deliver in proper site' do
        assert_deliveries 1
        assert_emails_delivered(@email, @group.people)
        assert_equal @site1, Site.current
      end
    end

    context 'given message to group in second site' do
      setup do
        @email = to_email(from: @site2user.email, to: 'group@two', subject: 'test', body: 'hello')
        Notifier.receive(@email.to_s)
      end

      should 'deliver in proper site' do
        assert_deliveries 1
        assert_emails_delivered(@email, @site2group.people)
        assert_equal @site2, Site.current
      end
    end

    context 'given message to group in second site from wrong address' do
      setup do
        @email = to_email(from: @user.email, to: 'group@two', subject: 'test', body: 'hello')
        Notifier.receive(@email.to_s)
        @sent = ActionMailer::Base.deliveries.first
      end

      should 'deliver in proper site' do
        assert_deliveries 1
        assert_equal @email.from, @sent.to
        assert_equal 'Message Rejected: test', @sent.subject
        assert_equal [Site.current.noreply_email], @sent.from
        assert_match(/the system does not recognize your email address/, @sent.body.to_s)
      end
    end

    teardown do
      Site.current = @site1
    end
  end

  should 'properly parse html email' do
    body = Notifier.get_body(Mail.read(File.join(FIXTURES_PATH, 'html.email')))
    assert_equal nil, body[:text]
    assert body[:html]
  end

  private
    def to_email(values)
      values.symbolize_keys!
      email = Mail.new do
        to      values[:to]
        cc      values[:cc] if values[:cc]
        from    values[:from]
        subject values[:subject]
        body    values[:body]
      end
      email
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
