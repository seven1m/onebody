# coding: utf-8

require 'rails_helper'
require 'notifier'

describe Notifier, type: :mailer do
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = 'utf-8'.freeze

  before do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    @user = FactoryGirl.create(:person)
    @group = FactoryGirl.create(:group, address: 'group')
    @membership = @group.memberships.create!(person: @user)
  end

  context 'given user not in group' do
    before do
      @non_member = FactoryGirl.create(:person, email: 'non-member@example.com')
      @email = to_email(
        from: @non_member.email,
        to: @group.full_address,
        subject: 'test to group from non-member',
        body: 'Hello Group'
      )
      Notifier.receive(@email.to_s)
    end

    it 'does not allow sending to the group' do
      expect(ActionMailer::Base.deliveries.size).to eq(1)
      delivered = ActionMailer::Base.deliveries.last
      expect(delivered.subject).to eq('Message Not Sent: test to group from non-member')
    end
  end

  context 'given user in group where members cannot send' do
    before do
      @group.update_attribute(:members_send, false)
      @email = to_email(
        from: @user.email,
        to: @group.full_address,
        subject: 'test to group from non-admin',
        body: 'Hello Group'
      )
      Notifier.receive(@email.to_s)
    end

    it 'does not allow sending to the group' do
      expect(ActionMailer::Base.deliveries.size).to eq(1)
      delivered = ActionMailer::Base.deliveries.last
      expect(delivered.subject).to eq('Message Not Sent: test to group from non-admin')
    end
  end

  context 'given 2 people in a group' do
    before do
      @user2 = FactoryGirl.create(:person)
      @group.memberships.create!(person: @user2)
    end

    context 'given an email sent from one of the members' do
      before do
        @email = to_email(
          from: @user.email,
          to: @group.full_address,
          subject: 'test to group from user',
          body: 'Hello Group'
        )
        Notifier.receive(@email.to_s)
      end

      it 'delivers the email to both users' do
        assert_deliveries 2
        assert_emails_delivered(@email, @group.people)
      end

      context 'given a reply from other member with original sender as TO address' do
        before do
          body = "reply\n\n" + ActionMailer::Base.deliveries.first.body.to_s # must contain message id from original
          ActionMailer::Base.deliveries = [] # reset deliveries
          @email = to_email(
            from: @user2.email,
            to: @user.email,
            cc: @group.full_address,
            subject: 're: Hello Group',
            body: body
          )
          Notifier.receive(@email.to_s)
        end

        it 'delivers the email to sender' do
          expect(ActionMailer::Base.deliveries.map(&:to).flatten).to include(@user2.email)
        end

        it 'does not deliver email to user who received it out-of-band' do
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

        it 'delivers the email to both members' do
          expect(ActionMailer::Base.deliveries.map(&:to).flatten.sort).to include(@user.email, @user2.email)
        end
      end

      context 'given a repy email with attachment' do
        before do
          @sent = ActionMailer::Base.deliveries.first
          reply = Mail.new(
            from:        "#{@user2.name} <#{@user2.email}>",
            to:          @group.full_address,
            subject:     're: Hello Group',
            in_reply_to: @sent.message_id
          )
          reply.text_part = Mail::Part.new do
            body 'hello!!!'
          end
          reply.attachments['myfile.pdf'] = File.read(Rails.root.join('spec/fixtures/files/attachment.pdf'))
          ActionMailer::Base.deliveries = []
          Notifier.receive(reply.to_s)
          @sent = ActionMailer::Base.deliveries.first
          @message = Message.last
        end

        it 'saves the attachment' do
          expect(@message.subject).to eq('re: Hello Group')
          expect(@message.attachments.count).to eq(1)
        end
      end
    end
  end

  context 'message sent to two groups' do
    before do
      @group2 = FactoryGirl.create(:group, address: 'group2')
      @membership = @group2.memberships.create!(person: @user)
    end

    context 'both group emails in the TO field' do
      before do
        @email = to_email(
          from: @user.email,
          to: [@group.full_address, @group2.full_address],
          subject: 'test to two groups',
          body: 'hello'
        )
        Notifier.receive(@email.to_s)
      end

      it 'delivers a message to each group' do
        assert_deliveries 2
        expect(delivered_emails_as_hashes).to include(
          include(subject: 'test to two groups', body: match(/group@example\.com/),  to: include(@user.email)),
          include(subject: 'test to two groups', body: match(/group2@example\.com/), to: include(@user.email))
        )
      end
    end

    context 'one group email in the TO field and one in the CC field' do
      before do
        @email = to_email(
          from: @user.email,
          to: [@group.full_address],
          cc: [@group2.full_address],
          subject: 'test to two groups',
          body: 'hello'
        )
        Notifier.receive(@email.to_s)
      end

      it 'delivers a message to each group' do
        assert_deliveries 2
        expect(delivered_emails_as_hashes).to include(
          include(subject: 'test to two groups', body: match(/group@example\.com/),  to: include(@user.email)),
          include(subject: 'test to two groups', body: match(/group2@example\.com/), to: include(@user.email))
        )
      end
    end

    context 'both group emails in the CC field' do
      before do
        @email = to_email(
          from: @user.email,
          to: ['irrelevant@example.com'],
          cc: [@group.full_address, @group2.full_address],
          subject: 'test to two groups',
          body: 'hello'
        )
        Notifier.receive(@email.to_s)
      end

      it 'delivers a message to each group' do
        assert_deliveries 2
        expect(delivered_emails_as_hashes).to include(
          include(subject: 'test to two groups', body: match(/group@example\.com/),  to: include(@user.email)),
          include(subject: 'test to two groups', body: match(/group2@example\.com/), to: include(@user.email))
        )
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
      @email = to_email(
        from: @user.email,
        to: @group.full_address,
        cc: 'peter@example.com',
        subject: 'test',
        body: 'hello'
      )
      Notifier.receive(@email.to_s)
      assert_emails_delivered(@email, @group.people)
      # now the second copy rolls in
      ActionMailer::Base.deliveries = []
      Notifier.receive(@email.to_s)
    end

    it 'does not send rejection if previous copy of message was delivered' do
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

    it 'does not deliver to same email address twice' do
      expect(ActionMailer::Base.deliveries.map(&:to).flatten.sort).to eq([@jack.email, @user.email])
    end
  end

  context 'given invalid message (no subject)' do
    before do
      email = to_email(from: @user.email, to: @group.full_address, subject: '', body: 'test!')
      Notifier.receive(email.to_s)
    end

    it 'sends a rejection notice' do
      assert_deliveries 1
      delivery = ActionMailer::Base.deliveries.first
      expect(delivery.to.first).to match(@user.email)
      expect(delivery.to_s).to match(/too short/)
    end
  end

  context 'given subject containing UTF-8 characters' do
    before do
      @email = "From: #{@user.email}\r\n" \
               "To: #{@group.full_address}\r\n" \
               "Content-Type: text/html; charset=\"LATIN-1\"\r\n" \
               "Subject: You don’t have to buy it all at frustrating prices!\r\n\r\n" \
               'test!'
      Notifier.receive(@email.to_s)
      @delivery = ActionMailer::Base.deliveries.last
    end

    it 'delivers the message' do
      assert_deliveries 1
      expect(@delivery.subject).to eq('You don’t have to buy it all at frustrating prices!')
    end
  end

  context 'given user sending from alternate email address' do
    before do
      @user.alternate_email = 'alternate@example.com'
      @user.save!
      email = to_email(
        from: 'alternate@example.com',
        to: @group.full_address,
        subject: 'test from my alternate',
        body: 'test!'
      )
      Notifier.receive(email.to_s)
    end

    it 'sends the message' do
      assert_deliveries 1
      delivery = ActionMailer::Base.deliveries.first
      expect(delivery.subject).to eq('test from my alternate')
      expect(Message.last.person).to eq(@user)
    end
  end

  context 'given two users in the same family with same email address' do
    before do
      @user.dont_mark_email_changed = true
      @user.email = 'shared@gmail.com'
      @user.first_name = 'Jim'
      @user.save!
      @spouse = FactoryGirl.create(:person, first_name: 'Jane', family: @user.family, email: 'shared@gmail.com')
      @membership2 = @group.memberships.create!(person: @spouse)
    end

    context 'given no name on email' do
      before do
        email = to_email(from: 'shared@gmail.com',
                         to: @group.full_address,
                         subject: 'test from my shared address',
                         body: 'test!')
        Notifier.receive(email.to_s)
      end

      it 'rejects the message' do
        assert_deliveries 1
        delivery = ActionMailer::Base.deliveries.first
        expect(delivery.subject).to eq('Message Not Sent: test from my shared address')
        expect(delivery.body).to match(/more than one person in your family share the same email address/)
      end
    end

    context 'given one person in the group and one is not' do
      before do
        @membership2.destroy
        email = to_email(from: 'shared@gmail.com',
                         to: @group.full_address,
                         subject: 'test from my shared address',
                         body: 'test!')
        Notifier.receive(email.to_s)
      end

      it 'sends the message, assigning to user belonging to the group' do
        assert_deliveries 1
        delivery = ActionMailer::Base.deliveries.first
        expect(delivery.subject).to eq('test from my shared address')
        expect(Message.last.person).to eq(@user)
      end
    end

    context 'given a name on email to help determine user' do
      before do
        email = to_email(from: 'Jane Smith <shared@gmail.com>',
                         to: @group.full_address,
                         subject: 'test from my shared address',
                         body: 'test!')
        Notifier.receive(email.to_s)
      end

      it 'sends the message, assigning to user with same first name' do
        assert_deliveries 1
        delivery = ActionMailer::Base.deliveries.first
        expect(delivery.subject).to eq('test from my shared address')
        expect(Message.last.person).to eq(@spouse)
      end
    end

    context 'given one person has primary_emailer=true' do
      before do
        @user.update_attribute(:primary_emailer, true)
        email = to_email(from: 'shared@gmail.com',
                         to: @group.full_address,
                         subject: 'test from my shared address',
                         body: 'test!')
        Notifier.receive(email.to_s)
      end

      it 'sends the message, assigning to user with primary_emailer=true' do
        assert_deliveries 1
        delivery = ActionMailer::Base.deliveries.first
        expect(delivery.subject).to eq('test from my shared address')
        expect(Message.last.person).to eq(@user)
      end
    end
  end

  it 'sends an email update' do
    Notifier.email_update(@user).deliver_now
    expect(ActionMailer::Base.deliveries).to_not be_empty
    sent = ActionMailer::Base.deliveries.first
    expect(sent.to).to eq([Setting.get(:contact, :send_email_changes_to)])
    expect(sent.subject).to eq("#{@user.name} Changed Email")
    expect(sent.body.to_s).to include("#{@user.name} has had their email changed.")
    expect(sent.body.to_s).to include("Email: #{@user.email}")
  end

  it 'sends a profile update' do
    Notifier.profile_update(@user).deliver_now
    expect(ActionMailer::Base.deliveries.size).to eq(1)
    sent = ActionMailer::Base.deliveries.last
    expect(sent.subject).to eq("Profile Update from #{@user.name}")
    expect(sent.body.to_s).to match(/has submitted a profile update/)
  end

  it 'sends a friend request' do
    @friend = FactoryGirl.create(:person)
    Notifier.friend_request(@user, @friend).deliver_now
    expect(ActionMailer::Base.deliveries.size).to eq(1)
    sent = ActionMailer::Base.deliveries.last
    expect(sent.subject).to eq("Friend Request from #{@user.name}")
    expect(sent.body.to_s).to match(/wants to be your friend/)
  end

  it 'sends a group membership request' do
    @admin = FactoryGirl.create(:person, :super_admin)
    Notifier.membership_request(@group, @user).deliver_now
    expect(ActionMailer::Base.deliveries.size).to eq(1)
    sent = ActionMailer::Base.deliveries.last
    expect(sent.subject).to eq("Request to Join Group from #{@user.name}")
    expect(sent.body.to_s).to match(/has requested to join the group/)
  end

  context 'given a private message between two people' do
    before do
      @user2 = FactoryGirl.create(:person, first_name: 'Jane')
      @message = Message.create person: @user, to: @user2, subject: 'test', body: 'hello'
      @sent = ActionMailer::Base.deliveries.first
    end

    it 'delivers the message' do
      expect(ActionMailer::Base.deliveries.length).to eq(1)
      expect(@sent.to).to eq([@user2.email])
      expect(@sent.subject).to eq('test')
      expect(@sent.body.to_s).to match(/^hello/)
    end

    it 'sets the reply-to address to the user actual email' do
      expect(@sent.reply_to.first).to eq(@user.email)
    end

    it 'maintains the message_id generated by OneBody' do
      expect(@sent.message_id).to match(/<#{@message.id_and_code}_/)
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

    it 'saves both the html and text part' do
      expect(@message.body).to match(/This is a test of complicated multipart message/)
      expect(@message.html_body).to match(%r{<p>This is a test of complicated multipart message.</p>})
    end

    it 'delivers the message to the group' do
      expect(ActionMailer::Base.deliveries.length).to eq(1)
    end

    it 'saves the attachment' do
      expect(@message.attachments.count).to eq(1)
    end
  end

  context 'email sent to the noreply address' do
    before do
      msg = Mail.new(
        from:    @user.email,
        to:      Site.current.noreply_email,
        subject: 're: test',
        body:    'hello!!!'
      )
      Notifier.receive(msg.to_s)
    end

    it 'does not deliver any messages' do
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

      it 'delivers in proper site' do
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

      it 'delivers in proper site' do
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

      it 'replies to the user with a rejection' do
        assert_deliveries 1
        expect(@sent.to).to eq(@email.from)
        expect(@sent.subject).to eq('Message Not Sent: test')
        expect(@sent.from).to eq([Site.current.noreply_email])
        expect(@sent.body.to_s).to match(/the system does not recognize/i)
      end
    end

    context 'given message to group in second site using email_host domain' do
      before do
        @site2.update_attribute(:email_host, 'two.alt')
        @email = to_email(from: @site2user.email, to: 'group@two.alt', subject: 'test', body: 'hello')
        Notifier.receive(@email.to_s)
        @sent = ActionMailer::Base.deliveries.first
      end

      it 'delivers in proper site' do
        assert_deliveries 1
        assert_emails_delivered(@email, @site2group.people)
        expect(Site.current).to eq(@site2)
      end
    end

    after do
      Site.current = @site1
    end
  end

  it 'properly parses html email' do
    body = Notifier.get_body(Mail.read(File.join(FIXTURES_PATH, 'html.email')))
    expect(body[:text]).to eq(nil)
    expect(body[:html]).to be
  end

  it 'rejects email without a text or html body' do
    email = File.read(File.join(FIXTURES_PATH, 'rich_text.email')).sub('FROM', @user.email)
    Notifier.receive(email)
    expect(ActionMailer::Base.deliveries.size).to eq(1)
    rejection = ActionMailer::Base.deliveries.last
    expect(rejection.subject).to eq('Message Not Sent: Rich Text test')
    expect(rejection.body).to match(/cannot read your message/)
  end

  it 'rejects email with a short subject' do
    email = Mail.new(
      from:    @user.email,
      to:      @group.full_address,
      subject: 'x',
      body:    'hello!!!'
    )
    Notifier.receive(email)
    expect(ActionMailer::Base.deliveries.size).to eq(1)
    rejection = ActionMailer::Base.deliveries.last
    expect(rejection.subject).to eq('Message Error: x')
    expect(rejection.body).to match(/message subject is too short/)
  end

  it 'replies to the sender when no valid destinations were recognized' do
    email = Mail.new(
      from:    @user.email,
      to:      "nothing@#{Site.current.host}",
      subject: 'email to nowhere',
      body:    'hello!!!'
    )
    Notifier.receive(email)
    expect(ActionMailer::Base.deliveries.size).to eq(1)
    rejection = ActionMailer::Base.deliveries.last
    expect(rejection.subject).to eq('Message Not Sent: email to nowhere')
    expect(rejection.body.to_s.tr("\n", ' ')).to match(/could not find any valid group addresses/)
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
