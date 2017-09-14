require_relative '../rails_helper'

describe Verification, type: :model do
  before do
    @person = FactoryGirl.create(:person, email: 'test@example.com', mobile_phone: '1234567890')
  end

  describe 'creation' do
    context 'by email' do
      before do
        @verification = Verification.new(email: 'test@example.com')
      end

      context 'given a person with email exists' do
        it 'should be valid' do
          expect(@verification).to be_valid
        end
      end
    end
  end

  context '#generate_security_code' do
    before do
      @verification = Verification.create(email: 'test@example.com')
    end

    it 'should store a random numeric code' do
      expect(@verification.code).to be >= Verification::MIN_CODE
      expect(@verification.code).to be <= Verification::MAX_CODE
    end
  end

  context 'validate fewer than MAX_DAILY_VERIFICATION_ATTEMPTS have been created' do
    context 'by email' do
      before do
        MAX_DAILY_VERIFICATION_ATTEMPTS.times do
          Verification.create!(email: 'test@example.com')
        end
        @verification = Verification.create(email: 'test@example.com')
      end

      it 'should add error to base' do
        expect(@verification.errors[:base]).to eq([I18n.t('accounts.verification_max_attempts_reached')])
      end
    end

    context 'by mobile phone' do
      before do
        MAX_DAILY_VERIFICATION_ATTEMPTS.times do
          Verification.create!(mobile_phone: '1234567890', carrier: 'AT&T')
        end
        @verification = Verification.create(mobile_phone: '1234567890')
      end

      it 'should add error to base' do
        expect(@verification.errors[:base]).to eq([I18n.t('accounts.verification_max_attempts_reached')])
      end
    end
  end

  context 'validate carrier' do
    context 'given a mobile verification without carrier' do
      before do
        @verification = Verification.new(mobile_phone: '1234567890')
      end

      it 'should not be valid' do
        expect(@verification).to_not be_valid
        expect(@verification.errors[:carrier]).to be
      end
    end
  end

  context '#save' do
    context 'given a mobile phone number matching an existing person' do
      before do
        @verification = Verification.new(mobile_phone: '1234567890', carrier: 'AT&T')
        @return = @verification.save
      end

      it 'should return true' do
        expect(@return).to eq(true)
      end

      it 'should not be verified' do
        expect(@verification.reload.verified?).to eq(false)
      end

      it 'should set email address to mobile gateway' do
        expect(@verification.reload.email).to eq('1234567890@txt.att.net')
      end

      it 'should send verification email' do
        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq('Verify Mobile Phone')
        expect(email.to_s).to match(/From: "CHURCH\.IO" <noreply@example\.com>/)
      end
    end

    context 'given an email matching an existing person' do
      before do
        @verification = Verification.new(email: 'test@example.com')
      end

      context 'person can sign in' do
        before do
          @return = @verification.save
        end

        it 'should return true' do
          expect(@return).to eq(true)
        end

        it 'should not be verified' do
          expect(@verification.reload.verified?).to eq(false)
        end

        it 'should send verification email' do
          email = ActionMailer::Base.deliveries.last
          expect(email.subject).to eq('Verify Email')
          expect(email.body.to_s).to match(/account\/verify_code\?id=\d+&code=\d+/)
        end
      end

      context 'person cannot sign in' do
        before do
          @person.update_attributes(status: :inactive)
          @return = @verification.save
        end

        it 'should return false' do
          expect(@return).to eq(false)
        end

        it 'should not send verification email' do
          expect(ActionMailer::Base.deliveries.last).to be_nil
        end
      end
    end

    context 'given an email matching an existing person alternate_email' do
      before do
        @person.alternate_email = 'test@other.com'
        @person.save!
        @verification = Verification.new(email: 'test@other.com')
      end

      context 'person can sign in' do
        before do
          @return = @verification.save
        end

        it 'should return true' do
          expect(@return).to eq(true)
        end

        it 'should not be verified' do
          expect(@verification.reload.verified?).to eq(false)
        end

        it 'should send verification email' do
          email = ActionMailer::Base.deliveries.last
          expect(email.subject).to eq('Verify Email')
          expect(email.to).to eq(['test@other.com'])
          expect(email.body.to_s).to match(/account\/verify_code\?id=\d+&code=\d+/)
        end
      end
    end
  end

  context '#check!' do
    before do
      @verification = Verification.create(email: 'test@example.com')
    end

    before do
      @verification.code = 100_000
    end

    context 'given the wrong code' do
      before do
        @result = @verification.check!(0)
      end

      it 'should return false' do
        expect(@result).to eq(false)
      end

      it 'should set verified=false' do
        expect(@verification.reload.verified).to eq(false)
      end
    end

    context 'given no matching people' do
      before do
        @verification = Verification.new(email: 'nonexist@example.com')
      end

      it 'should not be valid' do
        expect(@verification).to_not be_valid
      end
    end

    context 'given one matching person' do
      context 'given the matching code' do
        before do
          @result = @verification.check!('100000')
        end

        it 'should return true' do
          expect(@result).to eq(true)
        end

        it 'should set verified=true' do
          expect(@verification.reload.verified).to eq(true)
        end
      end
    end

    context 'given two matching people' do
      before do
        @person2 = FactoryGirl.create(:person, email: 'test@example.com', family: @person.family)
      end

      context 'given the matching code' do
        before do
          @result = @verification.check!('100000')
        end

        it 'should return true' do
          expect(@result).to eq(true)
        end

        it 'should set verified=true' do
          expect(@verification.reload.verified).to eq(true)
        end
      end
    end
  end
end
