require_relative '../spec_helper'
require 'notifier'

describe Notifier do
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  before do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    @user = FactoryGirl.create(:person)
    @group = FactoryGirl.create(:group, address: 'group')
    @membership = @group.memberships.create!(person: @user)
  end

  context 'given 2 people in a group' do
    before do
      @user2 = FactoryGirl.create(:person)
      @group.memberships.create!(person: @user2)
    end

    context 'given an email sent from one of the members' do
      before do
        @email = to_email(from: @user.email, to: @group.full_address, subject: 'test to group from user', body: 'Hello Group')
        Notifier.receive(@email.to_s)
      end

      it 'should delivers email to both users' do
        assert_deliveries 2
        assert_emails_delivered(@email, @group.people)
      end

      context 'given a reply from other member with original sender as TO address' do
        before do
          body = "reply\n\n" + ActionMailer::Base.deliveries.first.body.to_s # must contain message id from original
          ActionMailer::Base.deliveries = [] # reset deliveries
          @email = to_email(from: @user2.email, to: @user.email, cc: @group.full_address, subject: 're: Hello Group', body: body)
          Notifier.receive(@email.to_s)
        end

        it 'should deliver email to sender' do
          expect(ActionMailer::Base.deliveries.map(&:to).flatten).to include(@user2.email)
        end

        it 'should not deliver email to user who received it out-of-band' do
          expect(ActionMailer::Base.deliveries.map(&:to).flatten).to_not include(@user.email)
        end
      end

      context 'given a reply from other member with group address as TO address' do
        before do
          body = "reply\n\n" + ActionMailer::Base.deliveries.first.body.to_s # must contain message id from original
          ActionMailer::Base.deliveries = [] # reset deliveries
          @email = to_email(from: @user2.email, to: @group.full_address, subject: 're: Hello Group', body: body)
          Notifier.receive(@email.to_s)
        end

        it 'should deliver email to both members' do
          expect(ActionMailer::Base.deliveries.map(&:to).flatten.sort).to eq([@user.email, @user2.email])
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

    before do
      @email = to_email(from: @user.email, to: @group.full_address, cc: 'peter@example.com', subject: 'test', body: 'hello')
      Notifier.receive(@email.to_s)
      assert_emails_delivered(@email, @group.people)
      # now the second copy rolls in
      ActionMailer::Base.deliveries = []
      Notifier.receive(@email.to_s)
    end

    it 'should not send rejection if previous copy of message was delivered' do
      expect(ActionMailer::Base.deliveries).to eq([])
    end
  end

  context 'given two people in group with same email address' do
    before do
      @jack = FactoryGirl.create(:person, email: 'family@jackandjill.com')
      @jill = FactoryGirl.create(:person, email: 'family@jackandjill.com', family: @jack.family)
      @group.memberships.create!(person: @jack)
      @group.memberships.create!(person: @jill)
      email = to_email(from: @user.email, to: @group.full_address, subject: 'test', body: 'hello')
      Notifier.receive(email.to_s)
    end

    it 'should not deliver to same email address twice' do
      expect(ActionMailer::Base.deliveries.map(&:to).flatten.sort).to eq([@jack.email, @user.email])
    end
  end

  context 'given invalid email address' do
    before do
      email = to_email(from: @user.email, to: @group.full_address, subject: '')
      Notifier.receive(email.to_s)
    end

    it 'should send rejection notice' do
      assert_deliveries 1
      delivery = ActionMailer::Base.deliveries.first
      expect(delivery.to.first).to match(@user.email)
      expect(delivery.to_s).to match(/too short/)
    end
  end

  it 'should send email update' do
    Notifier.email_update(@user).deliver
    expect(ActionMailer::Base.deliveries).to_not be_empty
    sent = ActionMailer::Base.deliveries.first
    expect(sent.to).to eq([Setting.get(:contact, :send_email_changes_to)])
    expect(sent.subject).to eq("#{@user.name} Changed Email")
    expect(sent.body.to_s.index("#{@user.name} has had their email changed.")).to be
    expect(sent.body.to_s.index("Email: #{@user.email}")).to be
  end

  context 'given a private message between two people' do
    before do
      @user2 = FactoryGirl.create(:person, first_name: 'Jane')
      @message = Message.create person: @user, to: @user2, subject: 'test', body: 'hello'
      @sent = ActionMailer::Base.deliveries.first
    end

    it 'should deliver message' do
      expect(ActionMailer::Base.deliveries.length).to eq(1)
      expect(@sent.to).to eq([@user2.email])
      expect(@sent.subject).to eq("test")
      expect(@sent.body.to_s).to match(/^hello/)
    end

    it 'should deliver from special address' do
      expect(@sent.from.first).to eq("johnsmith@example.com")
    end

    it 'should maintain message_id generated by OneBody' do
      expect(@sent.message_id).to match(/<#{@message.id_and_code}_/)
    end

    context 'given a reply message' do
      before do
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

      it 'should deliver message' do
        expect(ActionMailer::Base.deliveries.length).to eq(1)
        expect(@sent.to).to eq([@user.email])
        expect(@sent.subject).to eq("re: test")
        expect(@sent.body.to_s).to match(/^hello!!!/)
      end

      it 'should deliver from special address' do
        expect(@sent.from.first).to eq("janesmith@example.com")
      end
    end

    context 'given a reply message without in-reply-to header' do
      before do
        reply = Mail.new(
          from:        "#{@user2.name} <#{@user2.email}>",
          to:          @sent.from,
          subject:     're: test',
          body:        'hello!!!' + @sent.body.to_s
        )
        ActionMailer::Base.deliveries = []
        Notifier.receive(reply.to_s)
      end

      it 'should match message based on id in body' do
        expect(Message.count).to eq(2)
        expect(Message.last.parent).to eq(@message)
      end
    end

    context 'given a reply message without any linkage to original' do
      before do
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

      it 'should deliver rejection notice to sender' do
        expect(ActionMailer::Base.deliveries.length).to eq(1)
        expect(@sent.to).to eq([@user2.email])
        expect(@sent.subject).to eq("Message Rejected: re: test")
        expect(@sent.from).to eq([Site.current.noreply_email])
        expect(@sent.body.to_s).to match(/not properly addressed/)
      end
    end

    context 'given a reply message with a mismatched to address' do
      before do
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

      it 'should match message based on id in body' do
        expect(Message.count).to eq(2)
        expect(Message.last.parent).to eq(@message)
      end
    end

    context 'given a reply message from an unknown sender' do
      before do
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

      it 'should deliver rejection notice to sender' do
        expect(ActionMailer::Base.deliveries.length).to eq(1)
        expect(@sent.to).to eq(["unknown@foo.com"])
        expect(@sent.subject).to eq("Message Rejected: re: test")
        expect(@sent.from).to eq([Site.current.noreply_email])
        expect(@sent.body.to_s).to match(/the system does not recognize your email address/)
      end
    end
  end

  context 'given multipart email with attachment' do
    before do
      raw = File.read(File.join(FIXTURES_PATH, 'multipart.email'))
      raw.gsub!(/FROM_ADDRESS/, @user.email)
      raw.gsub!(/TO_ADDRESS/, @group.full_address)
      Notifier.receive(raw)
      @message = Message.order('id desc').first
    end

    it 'should save both html and text part' do
      expect(@message.body).to match(/This is a test of complicated multipart message/)
      expect(@message.html_body).to match(/<p>This is a test of complicated multipart message.<\/p>/)
    end

    it 'should deliver the message to the group' do
      expect(ActionMailer::Base.deliveries.length).to eq(1)
    end

    it 'should save attachment' do
      expect(@message.attachments.count).to eq(1)
    end
  end

  context 'email sent to the noreply address' do
    before do
      msg = Mail.new(
        from:        @user.email,
        to:          Site.current.noreply_email,
        subject:     're: test',
        body:        'hello!!!'
      )
      Notifier.receive(msg.to_s)
    end

    it 'should not deliver any messages' do
      expect(ActionMailer::Base.deliveries.length).to eq(0)
    end
  end

  context 'given a group in another site' do
    before do
      @site1 = Site.current
      Site.current = @site2 = Site.create!(name: 'Site Two', host: 'two')
      @site2user = FactoryGirl.create(:person)
      @site2group = FactoryGirl.create(:group, address: 'group')
      @site2group.memberships.create!(person: @site2user)
    end

    context 'given message to group in first site' do
      before do
        @email = to_email(from: @user.email, to: 'group@example.com', subject: 'test', body: 'hello')
        Notifier.receive(@email.to_s)
      end

      it 'should deliver in proper site' do
        assert_deliveries 1
        assert_emails_delivered(@email, @group.people)
        expect(Site.current).to eq(@site1)
      end
    end

    context 'given message to group in second site' do
      before do
        @email = to_email(from: @site2user.email, to: 'group@two', subject: 'test', body: 'hello')
        Notifier.receive(@email.to_s)
      end

      it 'should deliver in proper site' do
        assert_deliveries 1
        assert_emails_delivered(@email, @site2group.people)
        expect(Site.current).to eq(@site2)
      end
    end

    context 'given message to group in second site from wrong address' do
      before do
        @email = to_email(from: @user.email, to: 'group@two', subject: 'test', body: 'hello')
        Notifier.receive(@email.to_s)
        @sent = ActionMailer::Base.deliveries.first
      end

      it 'should deliver in proper site' do
        assert_deliveries 1
        expect(@sent.to).to eq(@email.from)
        expect(@sent.subject).to eq("Message Rejected: test")
        expect(@sent.from).to eq([Site.current.noreply_email])
        expect(@sent.body.to_s).to match(/the system does not recognize your email address/)
      end
    end

    after do
      Site.current = @site1
    end
  end

  it 'should properly parse html email' do
    body = Notifier.get_body(Mail.read(File.join(FIXTURES_PATH, 'html.email')))
    expect(body[:text]).to eq(nil)
    expect(body[:html]).to be
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
