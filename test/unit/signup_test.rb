require_relative '../test_helper'

class SignupTest < ActiveSupport::TestCase

  context 'sign up is disabled' do
    setup do
      Setting.set(1, 'Features', 'Sign Up', false)
      @signup = FactoryGirl.build(:signup)
    end

    should 'not be valid' do
      assert !@signup.valid?
    end

    should 'have an error on base' do
      @signup.valid?
      msg = I18n.t('activemodel.errors.models.signup.attributes.base.disabled')
      assert_equal [msg], @signup.errors[:base]
    end

    context '#save' do
      should 'return false' do
        assert !@signup.save
      end
    end

    context '#save!' do
      should 'raise exception' do
        assert_raises(ArgumentError) { @signup.save! }
      end
    end
  end

  context 'sign up is enabled' do
    setup do
      Setting.set(1, 'Features', 'Sign Up', true)
    end

    context 'missing parameters' do
      setup do
        @signup = Signup.new
      end

      should 'not be valid' do
        assert !@signup.valid?
      end

      should 'have an error on first_name' do
        @signup.valid?
        msg = I18n.t('activemodel.errors.models.signup.attributes.first_name.blank')
        assert_equal [msg], @signup.errors[:first_name]
      end
    end

    context 'honeypot field contains text' do
      setup do
        @signup = Signup.new(a_phone_number: '1234567890')
      end

      should 'not be valid' do
        assert !@signup.valid?
      end

      should 'have an error on base' do
        @signup.valid?
        msg = I18n.t('activemodel.errors.models.signup.attributes.base.spam')
        assert_equal [msg], @signup.errors[:base]
      end
    end

    context 'valid parameters' do
      context 'user is an adult' do
        setup do
          @signup = FactoryGirl.build(:signup)
        end

        should 'be valid' do
          assert @signup.valid?
        end

        context 'sign up approval not required' do
          setup do
            Setting.set(:features, :sign_up_approval_email, nil)
            Notifier.deliveries.clear
          end

          context '#save' do
            setup do
              @family_count = Family.count
              @person_count = Person.count
              @return = @signup.save
            end

            should 'return true' do
              assert_equal true, @return
            end

            should 'create a new family' do
              assert_equal @family_count + 1, Family.count
              assert_equal 'John Smith', @signup.family.name
              assert_equal 'Smith', @signup.family.last_name
            end

            should 'create a new person' do
              assert_equal @person_count + 1, Person.count
            end

            context 'created person' do
              setup do
                @person = @signup.person
              end

              should 'have an email' do
                assert_equal 'john@example.com', @person.email
              end

              should 'have a name' do
                assert_equal 'John Smith', @person.name
              end

              should 'have a gender' do
                assert_equal 'Male', @person.gender
              end

              should 'have a birthday' do
                assert_equal Date.new(1980, 1, 1), @person.birthday
              end

              should 'be able to sign in' do
                assert_equal true, @person.can_sign_in?
              end

              should 'have full access' do
                assert_equal true, @person.full_access?
              end

              should 'be visible to everyone' do
                assert_equal true, @person.visible_to_everyone?
              end

              should 'be visible on printed directory' do
                assert_equal true, @person.visible_on_printed_directory?
              end

              should 'deliver email verification email to user' do
                assert_equal ['Verify Email'], Notifier.deliveries.map(&:subject)
              end
            end
          end

          context '#save!' do
            should 'return true' do
              assert_equal true, @signup.save!
            end
          end
        end

        context 'sign up approval required' do
          setup do
            Setting.set(:features, :sign_up_approval_email, 'admin@example.com')
            Notifier.deliveries.clear
          end

          context '#save' do
            setup do
              @return = @signup.save
            end

            should 'return true' do
              assert_equal true, @return
            end

            context 'created person' do
              setup do
                @person = @signup.person
              end

              should 'not be able to sign in' do
                assert_equal false, @person.can_sign_in?
              end

              should 'not have full access' do
                assert_equal false, @person.full_access?
              end

              should 'not be visible to everyone' do
                assert_equal false, @person.visible_to_everyone?
              end

              should 'not be visible on printed directory' do
                assert_equal false, @person.visible_on_printed_directory?
              end

              should 'deliver pending signup email to admin' do
                assert_equal ['Pending Sign Up'], Notifier.deliveries.map(&:subject)
              end
            end
          end
        end
      end

      context 'user is a child' do
        setup do
          @signup = FactoryGirl.build(:signup, birthday: 1.day.ago)
        end

        should 'not be valid' do
          assert !@signup.valid?
        end

        should 'have an error on birthday' do
          @signup.valid?
          msg = I18n.t('activemodel.errors.models.signup.attributes.birthday.too_young')
          assert_equal [msg], @signup.errors[:birthday]
        end
      end
    end
  end

end
