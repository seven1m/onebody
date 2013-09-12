require_relative '../test_helper'

class AccountsControllerTest < ActionController::TestCase

  def setup
    @person = FactoryGirl.create(:person)
  end

  context '#show' do
    context 'given a person_id param' do
      setup do
        get :show, {person_id: @person.id}, {logged_in_id: @person.id}
      end

      should 'redirect to the person account path' do
        assert_redirected_to person_account_path(@person)
      end
    end

    context 'given no params' do
      setup do
        get :show, {}, {logged_in_id: @person.id}
      end

      should 'redirect to the new account path' do
        assert_redirected_to new_account_path
      end
    end
  end

  context '#new' do
    context 'by email' do
      setup do
        get :new, {email: 'true'}
      end

      should 'render new_by_email template' do
        assert_template :new_by_email
      end
    end

    context 'by mobile phone' do
      setup do
        get :new, {phone: 'true'}
      end

      should 'render new_by_mobile template' do
        assert_template :new_by_mobile
      end
    end

    context 'by birthday' do
      setup do
        get :new, {birthday: 'true'}
      end

      should 'render new_by_birthday template' do
        assert_template :new_by_birthday
      end
    end

    context 'sign up feature enabled' do
      setup do
        Setting.set(1, 'Features', 'Sign Up', true)
        get :new
      end

      should 'render new template' do
        assert_template :new
      end
    end

    context 'sign up feature disabled' do
      setup do
        Setting.set(1, 'Features', 'Sign Up', false)
        get :new
      end

      should 'return failure message' do
        assert_response :not_found
        assert_select 'body', /page not found/i
      end
    end
  end

  context '#create' do
    context 'sign up' do
      context 'sign up feature disabled' do
        setup do
          Setting.set(1, 'Features', 'Sign Up', false)
          post :create, {person: {email: 'rick@example.com'}}
        end

        should 'set flash warning about required fields' do
          assert_match /required/i, flash[:warning]
        end

        should 'render new template again' do
          assert_template :new
        end
      end

      context 'sign up feature enabled' do
        setup do
          Setting.set(1, 'Features', 'Sign Up', true)
        end

        context 'spam sign up (honey pot phone field has text)' do
          setup do
            @count_was = Person.count
            post :create, {person: {email: 'rick@example.com'}, phone: '1234567890'}
          end

          should 'render new template' do
            assert_template :new
          end

          should 'not create a new person' do
            assert_equal @count_was, Person.count
          end
        end

        context 'valid sign up' do
          context 'no sign up approval needed' do
            setup do
              Setting.set(1, 'Features', 'Sign Up Approval Email', '')
            end

            context 'user is an adult' do
              setup do
                post :create, {person: {email: 'rick@example.com', first_name: 'Rick', last_name: 'Smith', birthday: '4/1/1980'}}
                @person = Person.last
              end

              should 'send email verification email' do
                assert_equal 'Verify Email', ActionMailer::Base.deliveries.last.subject
              end

              should 'create a new person' do
                assert_equal 'rick@example.com', @person.email
              end

              should 'create a new family' do
                assert @person.family
                assert_equal @person.name, @person.family.name
              end

              should 'set can_sign_in=true' do
                assert @person.can_sign_in?
              end

              should 'set full_access=true' do
                assert @person.full_access?
              end
            end

            context 'user is a child' do
              setup do
                ActionMailer::Base.deliveries.clear
                @count_was = Person.count
                post :create, {person: {email: 'rick@example.com', first_name: 'Rick', last_name: 'Smith', birthday: Date.today.to_s}}
              end

              should 'not send email' do
                assert_nil ActionMailer::Base.deliveries.last
              end

              should 'not create a new person' do
                assert_equal @count_was, Person.count
              end

              should 'render new template' do
                assert_template :new
              end

              should 'add an error to the record' do
                assert assigns[:person].errors[:base]
              end
            end
          end

          context 'sign up approval required' do
            setup do
              Setting.set(1, 'Features', 'Sign Up Approval Email', 'admin@example.com')
              post :create, {person: {email: 'rick@example.com', first_name: 'Rick', last_name: 'Smith', birthday: '4/1/1980'}}
              @person = Person.last
            end

            should 'send pending signup email' do
              assert_equal 'Pending Sign Up', ActionMailer::Base.deliveries.last.subject
            end

            should 'create a new person' do
              assert_equal 'rick@example.com', @person.email
            end

              should 'create a new family' do
                assert @person.family
                assert_equal @person.name, @person.family.name
              end

            should 'set can_sign_in=false' do
              refute @person.can_sign_in?
            end

            should 'set full_access=false' do
              refute @person.full_access?
            end
          end
        end

        context 'sign up with existing user email' do
          setup do
            @existing = FactoryGirl.create(:person, email: 'rick@example.com')
            post :create, {person: {email: 'rick@example.com'}}
          end

          should 'send email verification email' do
            assert_equal 'Verify Email', ActionMailer::Base.deliveries.last.subject
          end

          should 'indicate that email was sent' do
            assert_select 'body', /email.*sent/i
          end
        end

        context 'sign up missing name' do
          setup do
            post :create, {person: {email: 'rick@example.com', birthday: '4/1/1980'}}
          end

          should 'render the new template again' do
            assert_template :new
          end

          should 'fail to save the person' do
            assert assigns['person'].errors.any?
          end
        end
      end
    end

    context 'verify email' do
      context 'non-existent email' do
        setup do
          post :create, email: 'rick@example.com'
        end

        should 'indicate record not found' do
          assert_select '#main', /not.*found/i
        end
      end

      context 'email for existing user' do
        setup do
          @person = FactoryGirl.create(:person, email: 'rick@example.com')
        end

        context 'user can sign in' do
          setup do
            post :create, email: 'rick@example.com'
          end

          should 'send email verification email' do
            assert_equal 'Verify Email', ActionMailer::Base.deliveries.last.subject
          end

          should 'indicate that email was sent' do
            assert_select '#main', /email.*sent/i
          end
        end

        context 'user cannot sign in' do
          setup do
            @person.update_attribute(:can_sign_in, false)
            post :create, email: 'rick@example.com'
          end

          should 'redirect to page for bad status' do
            assert_redirected_to '/pages/system/bad_status'
          end
        end
      end
    end

    context 'verify mobile phone' do
      context 'non-existent mobile phone' do
        setup do
          post :create, phone: '1234567899', carrier: 'AT&T'
        end

        should 'indicate record not found' do
          assert_select '#notice', /not.*found/i
        end
      end

      context 'mobile phone for existing user' do
        setup do
          @person = FactoryGirl.create(:person, mobile_phone: '1234567899')
        end

        context 'user can sign in' do
          setup do
            post :create, phone: '1234567899', carrier: 'AT&T'
          end

          should 'send email verification email' do
            assert_equal 'Verify Mobile', ActionMailer::Base.deliveries.last.subject
          end

          should 'indicate that email was sent' do
            assert_select '#main', /message.*sent/i
          end
        end

        context 'user cannot sign in' do
          setup do
            @person.update_attribute(:can_sign_in, false)
            post :create, phone: '1234567899', carrier: 'AT&T'
          end

          should 'redirect to page for bad status' do
            assert_redirected_to '/pages/system/bad_status'
          end
        end
      end
    end

    context 'verify birthday' do
      setup do
        post :create, name: 'Rick Smith', email: 'rick@example.com', phone: '1234567899', birthday: '4/1/1980', notes: 'let me in!'
      end

      should 'send email to administrator' do
        assert_equal 'Birthday Verification', ActionMailer::Base.deliveries.last.subject
      end

      should 'indicate submission was sent' do
        assert_select '#main', /submission.*reviewed/i
      end
    end
  end

  context '#edit' do
    context 'user is account owner' do
      setup do
        get :edit, {person_id: @person.id}, {logged_in_id: @person.id}
      end

      should 'render the edit form' do
        assert_template :edit
      end
    end

    context 'user is not account owner' do
      setup do
        @stranger = FactoryGirl.create(:person)
        get :edit, {person_id: @person.id}, {logged_in_id: @stranger.id}
      end

      should 'return forbidden' do
        assert_response :forbidden
      end
    end

    context 'user is an admin with edit_profiles privilege' do
      setup do
        @admin = FactoryGirl.create(:person, admin: Admin.create!(edit_profiles: true))
        get :edit, {person_id: @person.id}, {logged_in_id: @admin.id}
      end

      should 'render the edit form' do
        assert_template :edit
      end
    end
  end

  context '#update' do
    context 'user is account owner' do
      setup do
        @password_was = @person.encrypted_password
        post :update, {person_id: @person.id, person: {email: 'foo@example.com', password: 'password', password_confirmation: 'password'}}, {logged_in_id: @person.id}
      end

      should 'redirect to the profile page' do
        assert_redirected_to person_path(@person)
      end

      should 'update email address' do
        assert_equal 'foo@example.com', @person.reload.email
      end

      should 'update password' do
        assert_not_equal @password_was, @person.reload.encrypted_password
      end

      context 'bad email given' do
        setup do
          post :update, {person_id: @person.id, person: {email: 'bad', password: 'password', password_confirmation: 'mismatched'}}, {logged_in_id: @person.id}
        end

        should 'be success' do
          assert_response :success
        end

        should 'render edit template again' do
          assert_template :edit
        end
      end

      context 'passwords do not match' do
        setup do
          post :update, {person_id: @person.id, person: {email: 'foo@example.com', password: 'password', password_confirmation: 'mismatched'}}, {logged_in_id: @person.id}
        end

        should 'be success' do
          assert_response :success
        end

        should 'render edit template again' do
          assert_template :edit
        end
      end
    end

    context 'user is not account owner' do
      setup do
        @stranger = FactoryGirl.create(:person)
        post :update, {person_id: @person.id, person: {email: 'foo@example.com', password: 'password', password_confirmation: 'password'}}, {logged_in_id: @stranger.id}
      end

      should 'return forbidden' do
        assert_response :forbidden
      end
    end

    context 'user is an admin with edit_profiles privilege' do
      setup do
        @admin = FactoryGirl.create(:person, admin: Admin.create!(edit_profiles: true))
        post :update, {person_id: @person.id, person: {email: 'foo@example.com', password: 'password', password_confirmation: 'password'}}, {logged_in_id: @admin.id}
      end

      should 'redirect' do
        assert_response :redirect
      end
    end
  end

  context '#select' do
    context 'GET with select people in session' do
      setup do
        @spouse = FactoryGirl.create(:person, family: @person.family)
        get :select, {}, {select_from_people: [@person, @spouse]}
      end

      should 'render select template' do
        assert_template :select
      end
    end

    context 'POST with select people in session' do
      context 'with a matching id' do
        setup do
          @spouse = FactoryGirl.create(:person, family: @person.family)
          post :select, {id: @spouse.id}, {select_from_people: [@person, @spouse]}
        end

        should 'redirect to edit person account path' do
          assert_redirected_to edit_person_account_path(@spouse)
        end

        should 'set flash to warn about setting password' do
          assert_match /set.*email.*password/, flash[:warning]
        end

        should 'clear session select people' do
          assert_nil session[:select_from_people]
        end
      end

      context 'without a matching id' do
        setup do
          @spouse = FactoryGirl.create(:person, family: @person.family)
          post :select, {id: '0'}, {select_from_people: [@person, @spouse]}
        end

        should 'return 200 OK status' do
          assert_response :success
        end

        should 'render select template again' do
          assert_template :select
        end

        should 'clear not session select people' do
          assert_equal [@person, @spouse], session[:select_from_people]
        end
      end
    end

    context 'GET with no select people in session' do
      setup do
        get :select, {}, {}
      end

      should 'return status 410 Gone' do
        assert_response :gone
      end

      should 'return page no longer valid' do
        assert_select 'body', /no longer valid/
      end
    end

    context 'POST with no select people in session' do
      setup do
        post :select, {id: @person.id}, {}
      end

      should 'return status 410 Gone' do
        assert_response :gone
      end

      should 'return page no longer valid' do
        assert_select 'body', /no longer valid/
      end
    end
  end

  context '#verify_code' do
    context 'given a non-pending email verification' do
      setup do
        @verification = Verification.create!(email: @person.email, verified: false)
      end

      should 'raise RecordNotFound exception' do
        assert_raise ActiveRecord::RecordNotFound do
          get :verify_code, {id: @verification.id}
        end
      end
    end

    context 'given a pending email verification' do
      setup do
        @verification = Verification.create!(email: @person.email)
      end

      context 'GET with proper id and code' do
        setup do
          get :verify_code, {id: @verification.id, code: @verification.code}
        end

        should 'mark the verification verified' do
          assert_equal true, @verification.reload.verified?
        end

        should 'redirect to edit person account' do
          assert_redirected_to edit_person_account_path(@person)
        end

        should 'set flash notice to set email' do
          assert_equal I18n.t('accounts.set_your_email_may_be_different'), flash[:warning]
        end

        should 'set logged in user in session' do
          assert_equal @person.id, session[:logged_in_id]
        end
      end

      context 'GET with improper id' do
        should 'raise RecordNotFound exception' do
          assert_raise ActiveRecord::RecordNotFound do
            get :verify_code, {id: '111111111'}
          end
        end
      end

      context 'GET with proper id and wrong code' do
        setup do
          get :verify_code, {id: @verification.id, code: '1'}
        end

        should 'not mark the verification verified' do
          assert_equal false, @verification.reload.verified?
        end

        should 'return 400 Bad Request' do
          assert_response :bad_request
        end

        should 'render text' do
          assert_select 'body', /wrong code/
        end
      end

      context 'matching more than one family member' do
        setup do
          @spouse = FactoryGirl.create(:person, family: @person.family, email: @person.email)
        end

        context 'GET with proper id and code' do
          setup do
            get :verify_code, {id: @verification.id, code: @verification.code}
          end

          should 'mark the verification verified' do
            assert_equal true, @verification.reload.verified?
          end

          should 'set select people in session' do
            assert_equal [@person, @spouse], session[:select_from_people]
          end

          should 'redirect to select account path' do
            assert_redirected_to select_account_path
          end
        end
      end
    end

    context 'given a pending mobile verification' do
      setup do
        @person.update_attribute :mobile_phone, '1234567891'
        @verification = Verification.create!(mobile_phone: @person.mobile_phone)
      end

      context 'GET with proper id and code' do
        setup do
          get :verify_code, {id: @verification.id, code: @verification.code}
        end

        should 'mark the verification verified' do
          assert_equal true, @verification.reload.verified?
        end

        should 'redirect to edit person account' do
          assert_redirected_to edit_person_account_path(@person)
        end

        should 'set flash notice to set email' do
          assert_match /set.*email/, flash[:warning]
        end
      end
    end
  end

  should "create account" do
    Setting.set(1, 'Features', 'Sign Up', true)
    post :create, {person: {email: 'user@example.com'}} # existing user
    assert_response :success
  end

  should "create account with birthday in american date format" do
    Setting.set(1, 'Features', 'Sign Up', true)
    Setting.set(1, 'Formats', 'Date', '%m/%d/%Y')
    post :create, {person: {email:      'bob@example.com',
                               first_name: 'Bob',
                               last_name:  'Morgan',
                               gender:     'Male',
                               birthday:   '01/02/1980'}}
    assert_response :success
    assert bob = Person.find_by_email('bob@example.com')
    assert_equal '01/02/1980', bob.birthday.strftime('%m/%d/%Y')
  end

  should "create account with birthday in european date format" do
    Setting.set(1, 'Features', 'Sign Up', true)
    Setting.set(1, 'Formats', 'Date', '%d/%m/%Y')
    post :create, {person: {email:      'bob@example.com',
                               first_name: 'Bob',
                               last_name:  'Morgan',
                               gender:     'Male',
                               birthday:   '02/01/1980'}}
    assert_response :success
    assert bob = Person.find_by_email('bob@example.com')
    assert_equal 'Jan 02, 1980', bob.birthday.strftime('%b %d, %Y')
  end

end
