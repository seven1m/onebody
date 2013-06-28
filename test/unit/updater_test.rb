require_relative '../test_helper'

class UpdaterTest < ActiveSupport::TestCase

  setup do
    @person = FactoryGirl.create(:person)
    @admin = FactoryGirl.create(:person, admin: Admin.create!(edit_profiles: true))
    @params = ActionController::Parameters.new(
      id: @person.id,
      person: {
        first_name:     'Tim',
        last_name:      'Morgan',
        suffix:         '',
        gender:         'Male',
        mobile_phone:   '1234567890',
        work_phone:     '2345678901',
        fax:            '3456789012',
        birthday:       '1/1/2000',
        anniversary:    '2/2/2000',
        description:    'Web Developer',
        email:          'tim@timmorgan.org',
        share_activity: 'true',
        member:         'true',
      },
      family: {
        name:           'Tim Morgan',
        last_name:      'Morgan',
        home_phone:     '4567890123',
        address1:       '123 S Something st.',
        address2:       '',
        city:           'City',
        state:          'OK',
        zip:            '00000',
      }
    )
  end

  context '#params' do
    context 'given a parameter that is not specified' do
      setup do
        params = {
          id: 1,
          person: {
            first_name: 'Jim',
            site_id: 2
          }
        }
        @actual = Updater.new(params).send(:params)
      end

      should 'be removed' do
        expected = {
          'person' => {'first_name' => 'Jim'}
        }
        assert_equal expected, @actual
      end
    end
  end

  context '#immediate_params' do
    context 'updates do need approval' do
      setup do
        Person.logged_in = @person
        Setting.set(Site.current.id, 'Features', 'Updates Must Be Approved', true)
        @actual = Updater.new(@params).send(:immediate_params)
      end

      should "return only parameters marked :immediate and :notify" do
        expected = {
          'person' => {
            'description'    => 'Web Developer',
            'email'          => 'tim@timmorgan.org',
            'share_activity' => 'true',
          }
        }
        assert_equal expected, @actual
      end
    end

    context 'updates do NOT need approval' do
      setup do
        Person.logged_in = @person
        Setting.set(Site.current.id, 'Features', 'Updates Must Be Approved', false)
        @actual = Updater.new(@params).send(:immediate_params)
      end

      should "return also parameters marked :approve" do
        assert_equal 'Tim', @actual[:person][:first_name]
      end
    end

    context 'user is admin' do
      setup do
        Person.logged_in = @admin
        Setting.set(Site.current.id, 'Features', 'Updates Must Be Approved', true)
        @actual = Updater.new(@params).send(:immediate_params)
      end

      should "return also parameters marked :approve" do
        assert_equal 'Tim', @actual[:person][:first_name]
      end

      should "return also parameters marked :admin" do
        assert_equal 'true', @actual[:person][:member]
      end
    end
  end

  context '#save!' do
    context 'updates do need approval' do
      setup do
        Person.logged_in = @person
        Setting.set(Site.current.id, 'Features', 'Updates Must Be Approved', true)
        @updater = Updater.new(@params)
        @updater.save!
        @update = Update.last
      end

      should 'not change the person model for first_name' do
        assert_equal 'John', @person.reload.first_name
        assert_nil @person.birthday
      end

      should 'change the person model for email' do
        assert_equal 'tim@timmorgan.org', @person.reload.email
      end

      should 'create an Update for first_name' do
        assert @update
      end

      should 'associate update with person' do
        assert_equal @person, @update.person
      end

      should 'not change the family model for city' do
        assert_nil @person.family.reload.city
      end
    end

    context 'updates do not need approval' do
      setup do
        Person.logged_in = @person
        Setting.set(Site.current.id, 'Features', 'Updates Must Be Approved', false)
        @updater = Updater.new(@params)
        @updater.save!
      end

      should 'change the person model directly' do
        assert_equal 'Tim', @person.reload.first_name
        assert_equal Time.utc(2000, 1, 1), @person.birthday
      end

      should 'change the family model directly' do
        assert_equal 'City', @person.family.reload.city
      end

      should 'not create an Update' do
        assert_nil Update.last
      end
    end

    context 'user is admin' do
      setup do
        Person.logged_in = @admin
        Setting.set(Site.current.id, 'Features', 'Updates Must Be Approved', true)
        @updater = Updater.new(@params)
        @updater.save!
      end

      should 'not create an Update' do
        assert_nil Update.last
      end
    end
  end

  context '#changes' do
    setup do
      Person.logged_in = @admin
      @updater = Updater.new(
        id: @person.id,
        person: {
          first_name: 'Tim',
          last_name: 'Smith'
        }
      )
    end

    should 'return only fields that are different' do
      expected = {
        'person' => {'first_name' => ['John', 'Tim']}
      }
      assert_equal expected, @updater.changes
    end

    should 'not retain temporarily changed attributes on internal models' do
      @updater.changes
      assert_empty @updater.send(:person).changes
    end

    should 'return the same changed values after models are saved' do
      @updater.save!
      expected = {
        'person' => {'first_name' => ['John', 'Tim']}
      }
      assert_equal expected, @updater.changes
    end
  end

end
