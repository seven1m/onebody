require_relative '../rails_helper'

describe AccountsController, type: :controller do
  render_views

  before do
    Setting.set(1, 'Privacy', 'Require Strong Password', false)
    @person = FactoryGirl.create(:person)
  end

  context '#show' do
    context 'given a person_id param' do
      before do
        get :show, { person_id: @person.id }, logged_in_id: @person.id
      end

      it 'should redirect to the person account path' do
        expect(response).to redirect_to(person_account_path(@person))
      end
    end

    context 'given no params' do
      before do
        get :show, {}, logged_in_id: @person.id
      end

      it 'should redirect to the new account path' do
        expect(response).to redirect_to(new_account_path)
      end
    end
  end

  context '#new' do
    context 'sign up feature disabled' do
      before do
        Setting.set(1, 'Features', 'Sign Up', false)
      end

      context 'verify account page' do
        before do
          get :new
        end

        it 'should render new template' do
          expect(response).to render_template(:new)
        end
      end

      context 'by email' do
        before do
          get :new, email: 'true'
        end

        it 'should render new_by_email template' do
          expect(response).to render_template(:new_by_email)
        end
      end

      context 'by mobile phone' do
        before do
          get :new, phone: 'true'
        end

        it 'should render new_by_mobile template' do
          expect(response).to render_template(:new_by_mobile)
        end
      end
    end

    context 'sign up feature enabled' do
      before do
        Setting.set(1, 'Features', 'Sign Up', true)
        get :new
      end

      it 'should render new template' do
        expect(response).to render_template(:new)
      end

      context 'verify by email' do
        before do
          get :new, email: 'true'
        end

        it 'should render new_by_email template' do
          expect(response).to render_template(:new_by_email)
        end
      end
    end
  end

  context '#create' do
    context 'sign up' do
      context 'sign up feature disabled' do
        before do
          Setting.set(1, 'Features', 'Sign Up', false)
          post :create, signup: { email: 'rick@example.com' }
        end

        it 'should render new template again' do
          expect(response).to render_template(:new)
        end
      end

      context 'sign up feature enabled' do
        before do
          Setting.set(1, 'Features', 'Sign Up', true)
        end

        context 'spam sign up (honeypot a_phone_number field has text)' do
          before do
            @count_was = Person.count
            post :create, signup: { email: 'rick@example.com', first_name: 'Rick', last_name: 'Smith', birthday: '4/1/1980', a_phone_number: '1234567890' }
          end

          it 'should render new template' do
            expect(response).to render_template(:new)
          end

          it 'should not create a new person' do
            expect(Person.count).to eq(@count_was)
          end
        end

        context 'valid sign up' do
          context 'no sign up approval needed' do
            before do
              Setting.set(1, 'Features', 'Sign Up Approval Email', '')
            end

            context 'user is an adult' do
              before do
                post :create, signup: { email: 'rick@example.com', mobile_phone: '0000000000', first_name: 'Rick', last_name: 'Smith', birthday: '4/1/1980' }
                expect(assigns[:signup].errors).to be_empty
                @person = Person.last
              end

              it 'should send email verification email' do
                expect(ActionMailer::Base.deliveries.last.subject).to eq('Verify Email')
              end

              it 'should create a new person' do
                expect(@person.email).to eq('rick@example.com')
              end

              it 'should create a new family' do
                expect(@person.family).to be
                expect(@person.family.name).to eq(@person.name)
              end

              it 'should set status=active' do
                expect(@person.status).to eq('active')
              end
            end

            context 'user is a child' do
              before do
                @count_was = Person.count
                post :create, signup: { email: 'rick@example.com', first_name: 'Rick', last_name: 'Smith', birthday: Date.current.to_s }
              end

              it 'should not send email' do
                expect(ActionMailer::Base.deliveries.last).to be_nil
              end

              it 'should not create a new person' do
                expect(Person.count).to eq(@count_was)
              end

              it 'should render new template' do
                expect(response).to render_template(:new)
              end

              it 'should add an error to the record' do
                expect(assigns[:signup].errors[:base]).to be
              end
            end
          end

          context 'sign up approval required' do
            before do
              Setting.set(1, 'Features', 'Sign Up Approval Email', 'admin@example.com')
              post :create, signup: { email: 'rick@example.com', mobile_phone: '0000000000', first_name: 'Rick', last_name: 'Smith', birthday: '4/1/1980' }
              expect(assigns[:signup].errors).to be_empty
              @person = Person.last
            end

            it 'should send pending signup email' do
              expect(ActionMailer::Base.deliveries.last.subject).to eq('Pending Sign Up')
            end

            it 'should create a new person' do
              expect(@person.email).to eq('rick@example.com')
            end

            it 'should create a new family' do
              expect(@person.family).to be
              expect(@person.family.name).to eq(@person.name)
            end

            it 'should set status=inactive' do
              expect(@person.status).to eq('inactive')
            end
          end
        end

        context 'sign up with existing user email' do
          before do
            @existing = FactoryGirl.create(:person, email: 'rick@example.com')
            post :create, signup: { email: 'rick@example.com', mobile_phone: '0000000000', first_name: 'Rick', last_name: 'Smith', birthday: '4/1/1980' }
          end

          it 'should send email verification email' do
            expect(ActionMailer::Base.deliveries.last.subject).to eq('Verify Email')
          end

          it 'should indicate that email was sent' do
            assert_select 'body', /email.*sent/i
          end
        end

        context 'sign up missing name' do
          before do
            post :create, signup: { email: 'rick@example.com', mobile_phone: '0000000000', birthday: '4/1/1980' }
          end

          it 'should render the new template again' do
            expect(response).to render_template(:new)
          end

          it 'should fail to save the signup' do
            expect(assigns['signup'].errors).to be_any
          end
        end
      end
    end

    context 'verify email' do
      context 'non-existent email' do
        before do
          post :create, verification: { email: 'rick@example.com' }, email: true
        end

        it 'should indicate record not found' do
          assert_select 'div.callout', /not.*found/i
        end
      end

      context 'email for existing user' do
        before do
          @person = FactoryGirl.create(:person, email: 'rick@example.com')
        end

        context 'user can sign in' do
          before do
            post :create, verification: { email: 'rick@example.com' }
          end

          it 'should send email verification email' do
            expect(ActionMailer::Base.deliveries.last.subject).to eq('Verify Email')
          end

          it 'should indicate that email was sent' do
            assert_select '.content', /email.*sent/i
          end
        end

        context 'user is inactive' do
          before do
            @person.update_attributes(status: :inactive)
            post :create, verification: { email: 'rick@example.com' }
          end

          it 'should show error message' do
            assert_select 'body', /There is a problem with your record preventing you from signing in/
          end
        end
      end
    end

    context 'verify mobile phone' do
      context 'non-existent mobile phone' do
        before do
          post :create, verification: { mobile_phone: '1234567899', carrier: 'AT&T' }, phone: true
        end

        it 'should indicate record not found' do
          expect(response).to render_template('new_by_mobile')
          assert_select 'body', /mobile number could not be found in our system/i
        end
      end

      context 'mobile phone for existing user' do
        before do
          @person = FactoryGirl.create(:person, mobile_phone: '1234567899')
        end

        context 'user can sign in' do
          before do
            post :create, verification: { mobile_phone: '1234567899', carrier: 'AT&T' }
          end

          it 'should send email verification email' do
            expect(ActionMailer::Base.deliveries.last.subject).to eq('Verify Mobile Phone')
          end

          it 'should indicate that message was sent' do
            assert_select '.content', /has been sent/i
          end
        end

        context 'user is inactive' do
          before do
            @person.update_attributes(status: :inactive)
            post :create, verification: { mobile_phone: '1234567899', carrier: 'AT&T' }
          end

          it 'should show error message' do
            assert_select 'body', /There is a problem with your record preventing you from signing in/
          end
        end
      end
    end
  end

  context '#edit' do
    context 'user is account owner' do
      before do
        get :edit, { person_id: @person.id }, logged_in_id: @person.id
      end

      it 'should render the edit form' do
        expect(response).to render_template(:edit)
      end
    end

    context 'user is not account owner' do
      before do
        @stranger = FactoryGirl.create(:person)
        get :edit, { person_id: @person.id }, logged_in_id: @stranger.id
      end

      it 'should return forbidden' do
        expect(response).to be_forbidden
      end
    end

    context 'user is an admin with edit_profiles privilege' do
      before do
        @admin = FactoryGirl.create(:person, admin: Admin.create!(edit_profiles: true))
        get :edit, { person_id: @person.id }, logged_in_id: @admin.id
      end

      it 'should render the edit form' do
        expect(response).to render_template(:edit)
      end
    end
  end

  context '#update' do
    context 'user is account owner' do
      before do
        @password_was = @person.password_hash
        post :update, { person_id: @person.id, person: { email: 'foo@example.com', password: 'password', password_confirmation: 'password' } }, logged_in_id: @person.id
      end

      it 'should redirect to the profile page' do
        expect(response).to redirect_to(person_path(@person))
      end

      it 'should update email address' do
        expect(@person.reload.email).to eq('foo@example.com')
      end

      it 'should update password' do
        expect(@person.reload.password_hash).to_not eq(@password_was)
      end

      context 'bad email given' do
        before do
          post :update, { person_id: @person.id, person: { email: 'bad', password: 'password', password_confirmation: 'mismatched' } }, logged_in_id: @person.id
        end

        it 'should be success' do
          expect(response).to be_success
        end

        it 'should render edit template again' do
          expect(response).to render_template(:edit)
        end
      end

      context 'passwords do not match' do
        before do
          post :update, { person_id: @person.id, person: { email: 'foo@example.com', password: 'password', password_confirmation: 'mismatched' } }, logged_in_id: @person.id
        end

        it 'should be success' do
          expect(response).to be_success
        end

        it 'should render edit template again' do
          expect(response).to render_template(:edit)
        end
      end

      context 'passwords too short' do
        before do
          Setting.set(1, 'Privacy', 'Minimum Password Characters', '7')
          post :update, { person_id: @person.id, person: { email: 'foo@example.com', password: 'pass', password_confirmation: 'pass' } }, logged_in_id: @person.id
        end

        it 'should be success' do
          expect(response).to be_success
        end

        it 'should render edit template again' do
          expect(response).to render_template(:edit)
        end
      end

      context 'passwords not strong enough' do
        before do
          Setting.set(1, 'Privacy', 'Require Strong Password', true)
          post :update, { person_id: @person.id, person: { password: '123456', password_confirmation: '123456' } }, logged_in_id: @person.id
        end

        it 'should be success' do
          expect(response).to be_success
        end

        it 'should render edit template again' do
          expect(response).to render_template(:edit)
        end
      end
    end

    context 'user is not account owner' do
      before do
        @stranger = FactoryGirl.create(:person)
        post :update, { person_id: @person.id, person: { email: 'foo@example.com', password: 'password', password_confirmation: 'password' } }, logged_in_id: @stranger.id
      end

      it 'should return forbidden' do
        expect(response).to be_forbidden
      end
    end

    context 'user is an admin with edit_profiles privilege' do
      before do
        @admin = FactoryGirl.create(:person, admin: Admin.create!(edit_profiles: true))
        post :update, { person_id: @person.id, person: { email: 'foo@example.com', password: 'password', password_confirmation: 'password' } }, logged_in_id: @admin.id
      end

      it 'should redirect' do
        expect(response).to be_redirect
      end
    end
  end

  context '#select' do
    context 'GET with select people in session' do
      before do
        @spouse = FactoryGirl.create(:person, family: @person.family)
        get :select, {}, select_from_people: [@person, @spouse]
      end

      it 'should render select template' do
        expect(response).to render_template(:select)
      end
    end

    context 'POST with select people in session' do
      context 'with a matching id' do
        before do
          @spouse = FactoryGirl.create(:person, family: @person.family)
          post :select, { id: @spouse.id }, select_from_people: [@person, @spouse]
        end

        it 'should redirect to edit person account path' do
          expect(response).to redirect_to(edit_person_account_path(@spouse))
        end

        it 'should set flash to warn about setting password' do
          expect(flash[:warning]).to match(/set.*email.*password/)
        end

        it 'should clear session select people' do
          expect(session[:select_from_people]).to be_nil
        end
      end

      context 'without a matching id' do
        before do
          @spouse = FactoryGirl.create(:person, family: @person.family)
          post :select, { id: '0' }, select_from_people: [@person, @spouse]
        end

        it 'should return 200 OK status' do
          expect(response).to be_success
        end

        it 'should render select template again' do
          expect(response).to render_template(:select)
        end

        it 'should clear not session select people' do
          expect(session[:select_from_people]).to eq([@person, @spouse])
        end
      end
    end

    context 'GET with no select people in session' do
      before do
        get :select, {}, {}
      end

      it 'should return status 410 Gone' do
        expect(response.status).to eq(410)
      end

      it 'should return page no longer valid' do
        assert_select 'body', /no longer valid/
      end
    end

    context 'POST with no select people in session' do
      before do
        post :select, { id: @person.id }, {}
      end

      it 'should return status 410 Gone' do
        expect(response.status).to eq(410)
      end

      it 'should return page no longer valid' do
        assert_select 'body', /no longer valid/
      end
    end
  end

  context '#verify_code' do
    context 'GET without a code' do
      before do
        @verification = Verification.create!(email: @person.email)
        get :verify_code, id: @verification.id
      end

      it 'renders the verify_code template' do
        expect(response).to render_template(:verify_code)
      end

      it 'does not auto-submit the form' do
        expect(response.body).to_not match(/submit\(\)/)
      end
    end

    context 'GET with a code' do
      before do
        @verification = Verification.create!(email: @person.email)
        get :verify_code, id: @verification.id, code: '1234'
      end

      it 'renders the verify_code template' do
        expect(response).to render_template(:verify_code)
      end

      it 'auto-submits the form' do
        expect(response.body).to match(/submit\(\)/)
      end
    end

    context 'given a non-pending email verification' do
      before do
        @verification = Verification.create!(email: @person.email, verified: false)
        post :verify_code, id: @verification.id
      end

      it 'should show a not valid message' do
        expect(response.body).to match(/no longer valid/)
      end
    end

    context 'given a pending email verification' do
      before do
        @verification = Verification.create!(email: @person.email)
      end

      context 'POST with proper id and code' do
        before do
          post :verify_code, id: @verification.id, code: @verification.code
        end

        it 'should mark the verification verified' do
          expect(@verification.reload.verified?).to eq(true)
        end

        it 'should redirect to edit person account' do
          expect(response).to redirect_to(edit_person_account_path(@person))
        end

        it 'should set flash notice to set email' do
          expect(flash[:warning]).to eq(I18n.t('accounts.set_your_email_may_be_different'))
        end

        it 'should set logged in user in session' do
          expect(session[:logged_in_id]).to eq(@person.id)
        end
      end

      context 'POST with improper id' do
        it 'should raise RecordNotFound exception' do
          expect { post :verify_code, id: '111111111' }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'POST with proper id and wrong code' do
        before do
          post :verify_code, id: @verification.id, code: '1'
        end

        it 'should not mark the verification verified' do
          expect(@verification.reload.verified?).to eq(false)
        end

        it 'should return 400 Bad Request' do
          expect(response).to be_bad_request
        end

        it 'should render text' do
          assert_select 'body', /wrong code/
        end
      end

      context 'matching more than one family member' do
        before do
          @spouse = FactoryGirl.create(:person, family: @person.family, email: @person.email)
        end

        context 'POST with proper id and code' do
          before do
            post :verify_code, id: @verification.id, code: @verification.code
          end

          it 'should mark the verification verified' do
            expect(@verification.reload.verified?).to eq(true)
          end

          it 'should set select people in session' do
            expect(session[:select_from_people]).to contain_exactly(@person, @spouse)
          end

          it 'should redirect to select account path' do
            expect(response).to redirect_to(select_account_path)
          end
        end
      end
    end

    context 'given a pending mobile verification' do
      before do
        @person.update_attribute :mobile_phone, '1234567891'
        @verification = Verification.create!(mobile_phone: @person.mobile_phone, carrier: 'AT&T')
      end

      context 'POST with proper id and code' do
        before do
          post :verify_code, id: @verification.id, code: @verification.code
        end

        it 'should mark the verification verified' do
          expect(@verification.reload.verified?).to eq(true)
        end

        it 'should redirect to edit person account' do
          expect(response).to redirect_to(edit_person_account_path(@person))
        end

        it 'should set flash notice to set email' do
          expect(flash[:warning]).to match(/set.*email/)
        end
      end
    end
  end

  it 'should create account with birthday in american date format' do
    Setting.set(1, 'Features', 'Sign Up', true)
    Setting.set(1, 'Formats', 'Date', '%m/%d/%Y')
    post :create, signup: { email:        'bob@example.com',
                            mobile_phone: '0000000000',
                            first_name:   'Bob',
                            last_name:    'Morgan',
                            gender:       'Male',
                            birthday:     '01/02/1980' }
    expect(response).to be_success
    expect(bob = Person.where(email: 'bob@example.com').first).to be
    expect(bob.birthday.strftime('%m/%d/%Y')).to eq('01/02/1980')
  end

  it 'should create account with birthday in european date format' do
    Setting.set(1, 'Features', 'Sign Up', true)
    Setting.set(1, 'Formats', 'Date', '%d/%m/%Y')
    post :create, signup: { email:        'bob@example.com',
                            mobile_phone: '0000000000',
                            first_name:   'Bob',
                            last_name:    'Morgan',
                            gender:       'Male',
                            birthday:     '02/01/1980' }
    expect(response).to be_success
    expect(bob = Person.where(email: 'bob@example.com').first).to be
    expect(bob.birthday.strftime('%b %d, %Y')).to eq('Jan 02, 1980')
  end
end
