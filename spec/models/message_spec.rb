require_relative '../rails_helper'

describe Message do
  include MessagesHelper

  before do
    @person, @second_person, @third_person = FactoryGirl.create_list(:person, 3)
    @admin_person = FactoryGirl.create(:person, admin: Admin.create(manage_groups: true))
    @group = Group.create! name: 'Some Group', category: 'test'
    @group.memberships.create! person: @person
    @group_admin = FactoryGirl.create(:person)
    @group_admin.memberships.create!(group: @group, admin: true)
  end

  it 'creates a new message with attachments' do
    files = [
      Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/attachment.pdf'), 'application/pdf', true)
    ]
    @message = Message.create_with_attachments(
      {
        to: @person,
        person: @second_person,
        subject: 'subject',
        body: 'body'
      },
      files
    )
    expect(@message.attachments.count).to eq(1)
  end

  it 'previews a message' do
    @preview = Message.preview(to: @person, person: @second_person, subject: 'subject', body: 'body')
    expect(@preview.subject).to eq('subject')
    @body = get_email_body(@preview)
    expect(@body.to_s.index('body')).to be
    expect(@body.to_s).to match(/Hit "Reply" to send a message/)
    expect(@body.to_s).to match(%r{http://.+\/privacy})
  end

  describe '#can_read?' do
    context 'group message' do
      before do
        @message = Message.create(group: @group, person: @person, subject: 'subject', body: 'body')
      end

      it 'knows who can see the message' do
        expect(@person.can_read?(@message)).to eq(true)
        expect(@second_person.can_read?(@message)).to be_falsey
        expect(@admin_person.can_read?(@message)).to be_falsey
        expect(@group_admin.can_read?(@message)).to eq(true)
      end

      context 'in a private group' do
        before do
          @group.update_attributes! private: true
        end

        it 'knows who can see the message' do
          expect(@person.can_read?(@message)).to eq(true)
          expect(@second_person.can_read?(@message)).to be_falsey
          expect(@admin_person.can_read?(@message)).to be_falsey
          expect(@group_admin.can_read?(@message)).to eq(true)
        end

        context 'admin cannot manage groups' do
          before do
            @admin_person.admin.update_attribute(:manage_groups, false)
          end

          it 'does not allow admin to see' do
            expect(@admin_person.can_read?(@message)).to be_falsey
          end
        end
      end
    end

    context 'private message' do
      before do
        @message = Message.create(to: @second_person, person: @person, subject: 'subject', body: 'body')
      end

      it 'knows who can see the message' do
        expect(@person.can_read?(@message)).to be
        expect(@second_person.can_read?(@message)).to be
        expect(@third_person.can_read?(@message)).not_to be
      end
    end
  end

  it 'allows a message without body if it has an html body' do
    @message = Message.create(subject: 'foo', html_body: 'bar', person: @person, group: @group)
    expect(@message).to be_valid
  end

  it 'is invalid if there is no body or html body' do
    @message = Message.create(subject: 'foo', person: @person, group: @group)
    expect(@message).to_not be_valid
    expect(@message.errors[:body]).to be_any
  end

  it 'does not allow two identical messages to be saved' do
    details = { subject: 'foo', body: 'foo', person: @person, group: @group }
    @message = Message.create!(details)
    @message2 = Message.new(details)
    expect(@message2).to_not be_valid
  end

  describe '#reply_instructions' do
    context 'message to a person' do
      let(:sender)    { FactoryGirl.create(:person, first_name: 'John', last_name: 'Doe') }
      let(:recipient) { FactoryGirl.create(:person) }
      let(:message)   { FactoryGirl.create(:message, to: recipient, person: sender, dont_send: true) }

      let(:instructions) { message.reply_instructions(recipient) }

      it 'tells the user to hit reply' do
        expect(instructions).to include(
          'Hit "Reply" to send a message to John Doe'
        )
      end
    end

    context 'message to a group' do
      let(:sender)    { FactoryGirl.create(:person, first_name: 'John', last_name: 'Doe') }
      let(:group)     { FactoryGirl.create(:group, name: 'Foo') }
      let(:recipient) { FactoryGirl.create(:person) }
      let(:message)   { FactoryGirl.create(:message, group: group, person: sender, dont_send: true) }

      context 'recipient cannot post to the group' do
        let!(:membership)  { group.memberships.create!(person: recipient) }
        let(:instructions) { message.reply_instructions(recipient) }

        it 'tells the user to hit reply' do
          expect(instructions).to include(
            'Hit "Reply" to send a message to John Doe'
          )
        end

        it 'does not tell the user to reply all' do
          expect(instructions).not_to include('Hit "Reply to All"')
        end

        it 'includes the group url' do
          expect(instructions).to match(
            %r{Group page: http://example.com/groups/\d+}i
          )
        end
      end

      context 'recipient can post to the group' do
        let(:group)        { FactoryGirl.create(:group, name: 'Foo', members_send: true, address: 'foo') }
        let!(:membership)  { group.memberships.create!(person: recipient) }
        let(:instructions) { message.reply_instructions(recipient) }

        it 'tells the user to hit reply' do
          expect(instructions).to include(
            'Hit "Reply" to send a message to John Doe'
          )
        end

        it 'tells the user to reply all' do
          expect(instructions).to include(
            'Hit "Reply to All" to send a message to the group Foo, or send to foo@example.com.'
          )
        end

        it 'includes the group url' do
          expect(instructions).to match(
            %r{Group page: http://example.com/groups/\d+}i
          )
        end

        context 'the group has no address' do
          before { group.update_attribute(:address, nil) }

          let(:instructions) { message.reply_instructions(recipient) }

          it 'does not tell the user to reply all' do
            expect(instructions).not_to include('Hit "Reply to All"')
          end

          it 'includes the url to the message' do
            expect(instructions).to include(
              "To reply, go to: http://example.com/messages/#{message.id}"
            )
          end
        end
      end
    end
  end

  describe '#disable_email_instructions' do
    context 'for a group' do
      let(:sender)    { FactoryGirl.create(:person, first_name: 'John', last_name: 'Doe') }
      let(:group)     { FactoryGirl.create(:group, name: 'Foo') }
      let(:recipient) { FactoryGirl.create(:person) }
      let(:message)   { FactoryGirl.create(:message, group: group, person: sender, dont_send: true) }

      let(:instructions) { message.disable_email_instructions(recipient) }

      it 'includes the link to disable group email' do
        expect(instructions).to match(
          /\ATo stop email from this group:\n.*email=off\n\z/
        )
      end
    end

    context 'for a person' do
      let(:sender)    { FactoryGirl.create(:person, first_name: 'John', last_name: 'Doe') }
      let(:recipient) { FactoryGirl.create(:person) }
      let(:message)   { FactoryGirl.create(:message, to: recipient, person: sender, dont_send: true) }

      let(:instructions) { message.disable_email_instructions(recipient) }

      it 'includes the link to the privacy page' do
        expect(instructions).to match(
          /\ATo stop these emails, go to your privacy page:\n.*privacy\n\z/
        )
      end
    end
  end

  describe '#members' do
    context 'A group that can send messages to the members' do
      let(:sender)    { FactoryGirl.create(:person) }
      let(:judas)     { FactoryGirl.create(:person, first_name: 'Judas', last_name: 'Iscariot') }
      let(:recipient) { FactoryGirl.create(:person) }
      let(:group)     { FactoryGirl.create(:group, members_send: true) }
      before(:each) { [sender, judas, recipient].each { |member| group.memberships.create! person: member } }

      subject do
        group.messages.create(subject: judas.name,
                              person:  sender,
                              body:    'Did you see who was talking to the Pharisies?',
                              member_ids: [recipient.id.to_s])
      end
      it 'is a personal message only sent to recipient' do
        expect(subject.group).not_to be
        expect(subject.to).to eq(recipient)
      end
    end
  end
end
