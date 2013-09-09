require_relative '../test_helper'

class VerificationTest < ActiveSupport::TestCase

  setup do
    @verification = Verification.create(email: 'test@example.com')
  end

  context '#generate_security_code' do
    should 'store a random numeric code' do
      assert_operator @verification.code, :>=, Verification::MIN_CODE
      assert_operator @verification.code, :<=, Verification::MAX_CODE
    end
  end

  context 'validate fewer than MAX_DAILY_VERIFICATION_ATTEMPTS have been created' do
    context 'by email' do
      setup do
        MAX_DAILY_VERIFICATION_ATTEMPTS.times do
          Verification.create!(email: 'test-limit@example.com')
        end
        @verification = Verification.create(email: 'test-limit@example.com')
      end

      should 'add error to base' do
        assert_equal [I18n.t('accounts.verification_max_attempts_reached')], @verification.errors[:base]
      end
    end

    context 'by mobile phone' do
      setup do
        MAX_DAILY_VERIFICATION_ATTEMPTS.times do
          Verification.create!(mobile_phone: '1234567890')
        end
        @verification = Verification.create(mobile_phone: '1234567890')
      end

      should 'add error to base' do
        assert_equal [I18n.t('accounts.verification_max_attempts_reached')], @verification.errors[:base]
      end
    end
  end

  context '#check!' do
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
      context 'given the matching code' do
        setup do
          @result = @verification.check!(100000)
        end

        should 'return false' do
          assert_equal false, @result
        end

        should 'set verified=false' do
          assert_equal false, @verification.reload.verified
        end
      end
    end

    context 'given one matching person' do
      setup do
        @person = FactoryGirl.create(:person, email: @verification.email)
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

    context 'given two matching people' do
      setup do
        @person1 = FactoryGirl.create(:person, email: @verification.email)
        @person2 = FactoryGirl.create(:person, email: @verification.email, family: @person1.family)
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
