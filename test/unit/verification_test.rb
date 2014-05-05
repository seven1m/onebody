require_relative '../test_helper'

class VerificationTest < ActiveSupport::TestCase

  setup do
    @person = FactoryGirl.create(:person, email: 'test@example.com', mobile_phone: '1234567890')
  end

  context 'creation' do
    context 'by email' do
      setup do
        @verification = Verification.new(email: 'test@example.com')
      end

      context 'given a person with email exists' do
        should 'be valid' do
          assert @verification.valid?
        end
      end
    end
  end

  context '#generate_security_code' do
    setup do
      @verification = Verification.create(email: 'test@example.com')
    end

    should 'store a random numeric code' do
      assert_operator @verification.code, :>=, Verification::MIN_CODE
      assert_operator @verification.code, :<=, Verification::MAX_CODE
    end
  end

  context 'validate fewer than MAX_DAILY_VERIFICATION_ATTEMPTS have been created' do
    context 'by email' do
      setup do
        MAX_DAILY_VERIFICATION_ATTEMPTS.times do
          Verification.create!(email: 'test@example.com')
        end
        @verification = Verification.create(email: 'test@example.com')
      end

      should 'add error to base' do
        assert_equal [I18n.t('accounts.verification_max_attempts_reached')], @verification.errors[:base]
      end
    end

    context 'by mobile phone' do
      setup do
        MAX_DAILY_VERIFICATION_ATTEMPTS.times do
          Verification.create!(mobile_phone: '1234567890', carrier: 'AT&T')
        end
        @verification = Verification.create(mobile_phone: '1234567890')
      end

      should 'add error to base' do
        assert_equal [I18n.t('accounts.verification_max_attempts_reached')], @verification.errors[:base]
      end
    end
  end

  context 'validate carrier' do
    context 'given a mobile verification without carrier' do
      setup do
        @verification = Verification.new(mobile_phone: '1234567890')
      end

      should 'not be valid' do
        assert !@verification.valid?
        assert @verification.errors[:carrier]
      end
    end
  end

  context '#save' do
    context 'given a mobile phone number matching an existing person' do
      setup do
        ActionMailer::Base.deliveries.clear
        @verification = Verification.new(mobile_phone: '1234567890', carrier: 'AT&T')
        @return = @verification.save
      end

      should 'return true' do
        assert_equal true, @return
      end

      should 'not be verified' do
        assert_equal false, @verification.reload.verified?
      end

      should 'set email address to mobile gateway' do
        assert_equal '1234567890@txt.att.net', @verification.reload.email
      end

      should 'send verification email' do
        assert_equal 'Verify Mobile', ActionMailer::Base.deliveries.last.subject
      end
    end

    context 'given an email matching an existing person' do
      setup do
        ActionMailer::Base.deliveries.clear
        @verification = Verification.new(email: 'test@example.com')
      end

      context 'person can sign in' do
        setup do
          @return = @verification.save
        end

        should 'return true' do
          assert_equal true, @return
        end

        should 'not be verified' do
          assert_equal false, @verification.reload.verified?
        end

        should 'send verification email' do
          email = ActionMailer::Base.deliveries.last
          assert_equal 'Verify Email', email.subject
          assert_match %r{account/verify_code\?id=\d+&code=\d+}, email.body.to_s
        end
      end

      context 'person cannot sign in' do
        setup do
          @person.update_attribute(:can_sign_in, false)
          @return = @verification.save
        end

        should 'return false' do
          assert_equal false, @return
        end

        should 'not send verification email' do
          assert_nil ActionMailer::Base.deliveries.last
        end
      end
    end
  end

  context '#check!' do
    setup do
      @verification = Verification.create(email: 'test@example.com')
    end

    setup do
      @verification.code = 100000
    end

    context 'given the wrong code' do
      setup do
        @result = @verification.check!(0)
      end

      should 'return false' do
        assert_equal false, @result
      end

      should 'set verified=false' do
        assert_equal false, @verification.reload.verified
      end
    end

    context 'given no matching people' do
      setup do
        @verification = Verification.new(email: 'nonexist@example.com')
      end

      should 'not be valid' do
        assert !@verification.valid?
      end
    end

    context 'given one matching person' do
      context 'given the matching code' do
        setup do
          @result = @verification.check!('100000')
        end

        should 'return true' do
          assert_equal true, @result
        end

        should 'set verified=true' do
          assert_equal true, @verification.reload.verified
        end
      end
    end

    context 'given two matching people' do
      setup do
        @person2 = FactoryGirl.create(:person, email: 'test@example.com', family: @person.family)
      end

      context 'given the matching code' do
        setup do
          @result = @verification.check!('100000')
        end

        should 'return true' do
          assert_equal true, @result
        end

        should 'set verified=true' do
          assert_equal true, @verification.reload.verified
        end
      end
    end
  end

end
