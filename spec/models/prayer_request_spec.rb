require_relative '../rails_helper'

describe PrayerRequest do
  before do
    @group = FactoryGirl.create(:group, name: 'Morgan Small Group')
    @person = FactoryGirl.create(:person)
    @group.memberships.create!(person: @person)
    @req = FactoryGirl.create(:prayer_request, group: @group, person: @person,
                                               request: 'the request', answered_at: nil, answer: nil)
  end

  it 'should have a name' do
    expect(@req.name).to eq("Prayer Request in #{@group.name}")
  end

  it "should have a name with a question mark if the group doesn't exist" do
    @group.destroy # does not destroy child prayer requests
    @req.reload
    expect(@req.name).to eq('Prayer Request in ?')
  end

  describe '#send_group_email' do
    before do
      Setting.set(:formats, :date, '%m/%d/%Y')
      OneBody.set_local_formats
      @group.memberships.create!(person: FactoryGirl.create(:person))
    end

    context 'with answer and answer date' do
      before do
        @req.update!(answer: 'the answer', answered_at: Date.new(2014, 9, 14))
        @req.send_group_email
        @email = ActionMailer::Base.deliveries.last
      end

      it 'sends an email with answer date heading and answer text' do
        expect(@email).to be
        expect(@email.subject).to eq('Prayer Request in Morgan Small Group')
        expect(@email.body).to match(/the request.*Answered on 09\/14\/2014.*the answer/m)
      end
    end

    context 'with answer but no answer date' do
      before do
        @req.update!(answer: 'the answer')
        @req.send_group_email
        @email = ActionMailer::Base.deliveries.last
      end

      it 'sends an email with answer heading (no date) and answer text' do
        expect(@email).to be
        expect(@email.subject).to eq('Prayer Request in Morgan Small Group')
        expect(@email.body).to match(/the request.*Answer\n.*the answer/m)
      end
    end

    context 'with no answer' do
      before do
        @req.answered_at = Date.new(2014, 9, 14) # just to make sure heading isn't shown
        @req.send_group_email
        @email = ActionMailer::Base.deliveries.last
      end

      it 'sends an email with answer heading (no date) and answer text' do
        expect(@email).to be
        expect(@email.subject).to eq('Prayer Request in Morgan Small Group')
        expect(@email.body).to match(/the request\s+$/m)
      end
    end
  end
end
