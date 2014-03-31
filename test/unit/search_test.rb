require_relative '../test_helper'

class SearchTest < ActiveSupport::TestCase

  def setup
    @user = FactoryGirl.create(:person)
    Person.logged_in = @user
  end

  context 'search by name' do
    setup do
      @search = Search.new
      @user.first_name = 'John'
      @user.last_name = 'Smith'
      @user.save!
    end

    should 'return person matching the first name' do
      @search.name = 'John'
      assert_equal [@user], @search.query
    end

    should 'return person matching the last name' do
      @search.name = 'Smith'
      assert_equal [@user], @search.query
    end

    should 'return person matching the full name' do
      @search.name = 'John Smith'
      assert_equal [@user], @search.query
    end

    should 'return none if no name matches' do
      @search.name = 'John Smithey'
      assert_equal [], @search.query
    end
  end

  context 'search by birthday' do
    setup do
      @search = Search.new
      @user.birthday = Date.new(1980, 1, 1)
      @user.save!
    end

    should 'return person matching the birthday day' do
      @search.birthday = {day: '1'}
      assert_equal [@user], @search.query
    end

    should 'return person matching the birthday month' do
      @search.birthday = {month: '1'}
      assert_equal [@user], @search.query
    end

    should 'return person matching the birthday month and day' do
      @search.birthday = {month: '1', day: '1'}
      assert_equal [@user], @search.query
    end

    should 'not return person if birthday is not matched' do
      @search.birthday = {month: '1', day: '2'}
      assert_equal [], @search.query
    end
  end

  context 'search by anniversary' do
    setup do
      @search = Search.new
      @user.anniversary = Date.new(1990, 2, 2)
      @user.save!
    end

    should 'return person matching the anniversary day' do
      @search.anniversary = {day: '2'}
      assert_equal [@user], @search.query
    end

    should 'return person matching the anniversary month' do
      @search.anniversary = {month: '2'}
      assert_equal [@user], @search.query
    end

    should 'return person matching the anniversary month and day' do
      @search.anniversary = {month: '2', day: '2'}
      assert_equal [@user], @search.query
    end

    should 'not return person if anniversary is not matched' do
      @search.anniversary = {month: '2', day: '3'}
      assert_equal [], @search.query
    end
  end

  context 'search by address' do
    setup do
      @search = Search.new
      @user.family.address1 = '123 S. Street'
      @user.family.city = 'Tulsa'
      @user.family.state = 'OK'
      @user.family.zip = '74010'
      @user.family.save!
    end

    should 'return person matching the address city' do
      @search.address = {city: 'Tulsa'}
      assert_equal [@user], @search.query
    end

    should 'return person matching the address state' do
      @search.address = {state: 'OK'}
      assert_equal [@user], @search.query
    end

    should 'return person matching the address zip' do
      @search.address = {zip: '74010'}
      assert_equal [@user], @search.query
    end

    should 'not return person if address does not match' do
      @search.address = {city: 'Tulsa', state: 'AR', zip: '74011'}
      assert_equal [], @search.query
    end
  end

  context 'search by type' do
    setup do
      @search = Search.new
    end

    should 'return members' do
      @search.type = 'member'
      assert_equal [], @search.query
      @user.member = true
      @user.save!
      assert_equal [@user], @search.query
    end

    should 'return staff' do
      @search.type = 'staff'
      assert_equal [], @search.query
      @user.staff = true
      @user.save!
      assert_equal [@user], @search.query
    end

    should 'return elder' do
      @search.type = 'elder'
      assert_equal [], @search.query
      @user.elder = true
      @user.save!
      assert_equal [@user], @search.query
    end
  end

  context 'given a child' do
    setup do
      @search = Search.new
      @child = FactoryGirl.create(:person, first_name: 'Mac', child: true)
    end

    context 'child does not have parental consent' do
      should 'not return child' do
        @search.name = 'mac'
        assert_equal [], @search.query
      end
    end

    context 'child has parental consent' do
      setup do
        @child.parental_consent = 'John Smith 1/1/2014'
        @child.save!
      end

      should 'return child' do
        @search.name = 'mac'
        assert_equal [@child], @search.query
      end
    end
  end

  context 'given a user under 18' do
    setup do
      @search = Search.new
      @search.name = 'jack'
      @minor = FactoryGirl.create(
        :person,
        first_name: 'Jack',
        birthday: 15.years.ago,
        parental_consent: 'John Smith 1/1/2014',
      )
    end

    context 'user does not have full access' do
      setup do
        @user.full_access = false
      end

      should 'not return minor in results' do
        assert_equal [], @search.query
      end
    end

    context 'user has full access' do
      setup do
        @user.full_access = true
      end

      should 'return minor in results' do
        assert_equal [@minor], @search.query
      end
    end
  end

  context 'search for families' do
    setup do
      @search = Search.new
      @search.family_name = 'Smith'
    end

    should 'return matching families by name' do
      assert_equal [@user.family], @search.query(1, 'family')
    end
  end
end
