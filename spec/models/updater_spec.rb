require_relative '../rails_helper'

describe Updater do
  before do
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
        member:         'true'
      },
      family: {
        name:           'Tim Morgan',
        last_name:      'Morgan',
        home_phone:     '4567890123',
        address1:       '123 S Something st.',
        address2:       '',
        city:           'City',
        state:          'OK',
        zip:            '00000'
      }
    )
  end

  context '#params' do
    context 'given a parameter that is not specified' do
      before do
        params = {
          id: 1,
          person: {
            first_name: 'Jim',
            site_id: 2
          }
        }
        @actual = Updater.new(params).params
      end

      it 'should be removed' do
        expected = {
          'person' => { 'first_name' => 'Jim' }
        }
        expect(@actual.to_h).to eq(expected)
      end
    end

    context 'given a parameter that is blank' do
      before do
        params = {
          id: 1,
          person: {
            mobile_phone: ''
          }
        }
        @actual = Updater.new(params).params
      end

      it 'should be nil' do
        expected = {
          'person' => { 'mobile_phone' => nil }
        }
        expect(@actual.to_h).to eq(expected)
      end
    end
  end

  context '#immediate_params' do
    context 'updates do need approval' do
      before do
        Person.logged_in = @person
        Setting.set(Site.current.id, 'Features', 'Updates Must Be Approved', true)
        @actual = Updater.new(@params).send(:immediate_params)
      end

      it 'should return only parameters marked :immediate and :notify' do
        expected = {
          'person' => {
            'description'    => 'Web Developer',
            'email'          => 'tim@timmorgan.org',
            'share_activity' => 'true'
          }
        }
        expect(@actual.to_h).to eq(expected)
      end
    end

    context 'updates do NOT need approval' do
      before do
        Person.logged_in = @person
        Setting.set(Site.current.id, 'Features', 'Updates Must Be Approved', false)
        @actual = Updater.new(@params).send(:immediate_params)
      end

      it 'should return also parameters marked :approve' do
        expect(@actual[:person][:first_name]).to eq('Tim')
      end

      after do
        Setting.set(Site.current.id, 'Features', 'Updates Must Be Approved', true)
      end
    end

    context 'user is admin' do
      before do
        Person.logged_in = @admin
        Setting.set(Site.current.id, 'Features', 'Updates Must Be Approved', true)
        @actual = Updater.new(@params).send(:immediate_params)
      end

      it 'should return also parameters marked :approve' do
        expect(@actual[:person][:first_name]).to eq('Tim')
      end

      it 'should return also parameters marked :admin' do
        expect(@actual[:person][:member]).to eq('true')
      end
    end
  end

  context '#save!' do
    context 'updates do need approval' do
      before do
        Person.logged_in = @person
        Setting.set(Site.current.id, 'Features', 'Updates Must Be Approved', true)
        @updater = Updater.new(@params)
        @updater.save!
        @update = Update.last
      end

      it 'should not change the person model for first_name' do
        expect(@person.reload.first_name).to eq('John')
        expect(@person.birthday).to be_nil
      end

      it 'should change the person model for email' do
        expect(@person.reload.email).to eq('tim@timmorgan.org')
      end

      it 'should create an Update for first_name' do
        expect(@update).to be
      end

      it 'should associate update with person' do
        expect(@update.person).to eq(@person)
      end

      it 'should not change the family model for city' do
        expect(@person.family.reload.city).to be_nil
      end
    end

    context 'updates do not need approval' do
      before do
        Person.logged_in = @person
        Setting.set(Site.current.id, 'Features', 'Updates Must Be Approved', false)
        @updater = Updater.new(@params)
        @updater.save!
      end

      it 'should change the person model directly' do
        expect(@person.reload.first_name).to eq('Tim')
        expect(@person.birthday).to eq(Time.utc(2000, 1, 1))
      end

      it 'should change the family model directly' do
        expect(@person.family.reload.city).to eq('City')
      end

      it 'should not create an Update' do
        expect(Update.last).to be_nil
      end

      after do
        Setting.set(Site.current.id, 'Features', 'Updates Must Be Approved', true)
      end
    end

    context 'user is admin' do
      before do
        Person.logged_in = @admin
        Setting.set(Site.current.id, 'Features', 'Updates Must Be Approved', true)
        @updater = Updater.new(@params)
        @updater.save!
      end

      it 'should not create an Update' do
        expect(Update.last).to be_nil
      end
    end
  end

  context '#changes' do
    before do
      Person.logged_in = @admin
      @updater = Updater.new(
        id: @person.id,
        person: {
          first_name: 'Tim',
          last_name: 'Smith'
        }
      )
    end

    it 'should return only fields that are different' do
      expected = {
        'person' => { 'first_name' => %w(John Tim) }
      }
      expect(@updater.changes).to eq(expected)
    end

    it 'should not retain temporarily changed attributes on internal models' do
      @updater.changes
      expect(@updater.send(:person).changes).to be_empty
    end

    it 'should return the same changed values after models are saved' do
      @updater.save!
      expected = {
        'person' => { 'first_name' => %w(John Tim) }
      }
      expect(@updater.changes).to eq(expected)
    end
  end

  context 'family update only' do
    before do
      Person.logged_in = @person
      @family = @person.family
      @updater = FamilyUpdater.new(
        id: @family.id,
        family: {
          name: 'Jack Smith',
          last_name: 'Smith',
          home_phone: '1234567890'
        }
      )
      @updater.save!
      @update = Update.last
    end

    it 'should create an Update for last_name' do
      expect(@update.diff).to eq(
        'person' => {},
        'family' => {
          'name'        => ['John Smith', 'Jack Smith'],
          'home_phone'  => [nil,          '1234567890']
        }
      )
    end
  end
end
