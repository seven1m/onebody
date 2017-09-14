require_relative '../rails_helper'

describe Signup, type: :model do
  context 'sign up is disabled' do
    before do
      Setting.set(1, 'Features', 'Sign Up', false)
      @signup = FactoryGirl.build(:signup)
    end

    it 'should not be valid' do
      expect(@signup).to_not be_valid
    end

    it 'should have an error on base' do
      @signup.valid?
      msg = I18n.t('activemodel.errors.models.signup.attributes.base.disabled')
      expect(@signup.errors[:base]).to eq([msg])
    end

    context '#save' do
      it 'should return false' do
        expect(@signup.save).not_to be
      end
    end

    context '#save!' do
      it 'should raise exception' do
        expect { @signup.save! }.to raise_error(ArgumentError)
      end
    end
  end

  context 'sign up is enabled' do
    before do
      Setting.set(1, 'Features', 'Sign Up', true)
    end

    context 'missing parameters' do
      before do
        @signup = Signup.new
      end

      it 'should not be valid' do
        expect(@signup).to_not be_valid
      end

      it 'should have an error on first_name' do
        @signup.valid?
        msg = I18n.t('activemodel.errors.models.signup.attributes.first_name.blank')
        expect(@signup.errors[:first_name]).to eq([msg])
      end
    end

    context 'user already exists with email' do
      before do
        @person = FactoryGirl.create(:person, email: 'me@example.com')
        @signup = FactoryGirl.build(:signup, email: 'ME@EXAMPLE.com') # intentionally uppercase
      end

      it 'should be valid' do
        expect(@signup).to be_valid
      end

      context '#save' do
        before do
          @family_count = Family.count
          @person_count = Person.count
        end

        context 'existing user can sign in' do
          before do
            @return = @signup.save
          end

          it 'should return true' do
            expect(@return).to eq(true)
          end

          it 'should not create any records' do
            expect(Family.count).to eq(@family_count)
            expect(Person.count).to eq(@person_count)
          end

          it 'should deliver email verification email to user' do
            expect(Notifier.deliveries.size).to eq(1)
            expect(Notifier.deliveries.last.subject).to eq('Verify Email')
            expect(Notifier.deliveries.last.to).to eq(['me@example.com'])
          end

          context '#verification_sent?' do
            it 'should return true' do
              expect(@signup.verification_sent?).to eq(true)
            end
          end

          context '#approval_sent?' do
            it 'should return false' do
              expect(@signup.approval_sent?).to eq(false)
            end
          end

          context '#found_existing?' do
            it 'should return true' do
              expect(@signup.found_existing?).to eq(true)
            end
          end
        end

        context 'existing user cannot sign in' do
          before do
            @person.update_attributes(status: :inactive)
          end

          context 'approval required for new users' do
            before do
              Setting.set(:features, :sign_up_approval_email, 'admin@example.com')
              @return = @signup.save
            end

            it 'should return true' do
              expect(@return).to eq(true)
            end

            it 'does not change status' do
              expect(@signup.person.reload).to be_inactive
            end

            context '#verification_sent?' do
              it 'should return false' do
                expect(@signup.verification_sent?).to eq(false)
              end
            end

            context '#approval_sent?' do
              it 'should return true' do
                expect(@signup.approval_sent?).to eq(true)
              end
            end
          end

          context 'approval not required for new users' do
            before do
              Setting.set(:features, :sign_up_approval_email, nil)
              @return = @signup.save
            end

            it 'should return true' do
              expect(@return).to eq(true)
            end

            it 'sets the user to active' do
              expect(@signup.person.reload).to be_active
            end

            context '#verification_sent?' do
              it 'should return true' do
                expect(@signup.verification_sent?).to eq(true)
              end
            end

            context '#approval_sent?' do
              it 'should return false' do
                expect(@signup.approval_sent?).to eq(false)
              end
            end
          end
        end
      end
    end

    context 'user already exists with mobile phone' do
      before do
        @person = FactoryGirl.create(:person, mobile_phone: '1234567890')
        @signup = FactoryGirl.build(:signup, email: 'a@b', mobile_phone: '(123) 456-7890')
      end

      it 'should be valid' do
        expect(@signup).to be_valid
      end

      context '#save' do
        before do
          @family_count = Family.count
          @person_count = Person.count
          @return = @signup.save
        end

        it 'should return true' do
          expect(@return).to eq(true)
        end

        it 'should not create any records' do
          expect(Family.count).to eq(@family_count)
          expect(Person.count).to eq(@person_count)
        end

        it 'should not deliver verification email to user' do
          expect(Notifier.deliveries).to be_empty
        end

        context '#verification_sent?' do
          it 'should return false' do
            expect(@signup.verification_sent?).to eq(false)
          end
        end

        context '#approval_sent?' do
          it 'should return false' do
            expect(@signup.approval_sent?).to eq(false)
          end
        end

        context '#can_verify_mobile?' do
          it 'should return true' do
            expect(@signup.can_verify_mobile?).to eq(true)
          end
        end

        context '#found_existing?' do
          it 'should return true' do
            expect(@signup.found_existing?).to eq(true)
          end
        end
      end
    end

    context 'honeypot field contains text' do
      before do
        @signup = Signup.new(a_phone_number: '1234567890')
      end

      it 'should not be valid' do
        expect(@signup).to_not be_valid
      end

      it 'should have an error on base' do
        @signup.valid?
        msg = I18n.t('activemodel.errors.models.signup.attributes.base.spam')
        expect(@signup.errors[:base]).to eq([msg])
      end
    end

    context 'valid parameters' do
      context 'user is an adult' do
        before do
          @signup = FactoryGirl.build(:signup)
        end

        it 'should be valid' do
          expect(@signup).to be_valid
        end

        context 'sign up approval not required' do
          before do
            Setting.set(:features, :sign_up_approval_email, nil)
          end

          context '#save' do
            before do
              @family_count = Family.count
              @person_count = Person.count
              @return = @signup.save
            end

            it 'should return true' do
              expect(@return).to eq(true)
            end

            it 'should create a new family' do
              expect(Family.count).to eq(@family_count + 1)
              expect(@signup.family.name).to eq('John Smith')
              expect(@signup.family.last_name).to eq('Smith')
            end

            it 'should create a new person' do
              expect(Person.count).to eq(@person_count + 1)
            end

            it 'should deliver email verification email to user' do
              expect(Notifier.deliveries.map(&:subject)).to eq(['Verify Email'])
            end

            context 'created person' do
              before do
                @person = @signup.person
              end

              it 'should have an email' do
                expect(@person.email).to eq('john@example.com')
              end

              it 'should have a name' do
                expect(@person.name).to eq('John Smith')
              end

              it 'should have a gender' do
                expect(@person.gender).to eq('Male')
              end

              it 'should have a birthday' do
                expect(@person.birthday).to eq(Date.new(1980, 1, 1))
              end

              it 'should have a mobile phone' do
                expect(@person.mobile_phone).to eq('1234567890')
              end

              it 'should be active' do
                expect(@person).to be_active
              end
            end
          end

          context '#save!' do
            it 'should return true' do
              expect(@signup.save!).to eq(true)
            end
          end

          context '#found_existing?' do
            it 'should return false' do
              expect(@signup.found_existing?).to eq(false)
            end
          end
        end

        context 'sign up approval required' do
          before do
            Setting.set(:features, :sign_up_approval_email, 'admin@example.com')
          end

          context '#save' do
            before do
              @return = @signup.save
            end

            it 'should return true' do
              expect(@return).to eq(true)
            end

            context '#verification_sent?' do
              it 'should return false' do
                expect(@signup.verification_sent?).to eq(false)
              end
            end

            context '#approval_sent?' do
              it 'should return true' do
                expect(@signup.approval_sent?).to eq(true)
              end
            end

            context 'created person' do
              before do
                @person = @signup.person
              end

              it 'should not be active' do
                expect(@person).not_to be_active
              end

              it 'should deliver pending signup email to admin' do
                expect(Notifier.deliveries.map(&:subject)).to eq(['Pending Sign Up'])
              end
            end
          end
        end
      end

      context 'user is a child' do
        before do
          @signup = FactoryGirl.build(:signup, birthday: 1.day.ago)
        end

        it 'should not be valid' do
          expect(@signup).to_not be_valid
        end

        it 'should have an error on birthday' do
          @signup.valid?
          msg = I18n.t('activemodel.errors.models.signup.attributes.birthday.too_young')
          expect(@signup.errors[:birthday]).to eq([msg])
        end
      end
    end
  end
end
