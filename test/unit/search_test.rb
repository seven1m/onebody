require_relative '../test_helper'

class SearchTest < ActiveSupport::TestCase

  def setup
    Person.delete_all # FIXME fixtures suck
    Family.delete_all # FIXME fixtures suck
    @user = FactoryGirl.create(:person)
    Person.logged_in = @user
    @nobody = FactoryGirl.create(:person, first_name: 'Jack', last_name: 'Jones', family: FactoryGirl.create(:family, name: 'Jack Jones', last_name: 'Jones'))
  end

  should 'not return deleted people' do
    @deleted = FactoryGirl.create(:person, deleted: true)
    assert !Search.new.results.include?(@deleted)
  end

  should 'not return people from deleted families' do
    @deleted_family = FactoryGirl.create(:family, deleted: true)
    @person = FactoryGirl.create(:person, family: @deleted_family)
    assert !Search.new.results.include?(@person)
  end

  should 'return people in alphabetical order by last, first' do
    @a = FactoryGirl.create(:person, first_name: 'a', last_name: 'a')
    @z = FactoryGirl.create(:person, first_name: 'z', last_name: 'z')
    assert_equal @a, Search.new.results.first
    assert_equal @z, Search.new.results.last
  end

  context 'search by name' do
    setup do
      @search = Search.new
      @user.first_name = 'John'
      @user.last_name = 'Smith'
      @user.save!
      @user.family.name = 'Johnny Smith'
      @user.family.save!
    end

    should 'return person matching the first name' do
      @search.name = 'John'
      assert_equal [@user], @search.results
    end

    should 'return person matching the last name' do
      @search.name = 'Smith'
      assert_equal [@user], @search.results
    end

    should 'return person matching the full name' do
      @search.name = 'John Smith'
      assert_equal [@user], @search.results
    end

    should 'return none if no name matches' do
      @search.name = 'John Smithey'
      assert_equal [], @search.results
    end

    should 'return person matching first part of each name' do
      @search.name = 'Jo Smi'
      assert_equal [@user], @search.results
    end

    should 'return person based on family name' do
      @search.name = 'Johnny Smith'
      assert_equal [@user], @search.results
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
      assert_equal [@user], @search.results
    end

    should 'return person matching the birthday month' do
      @search.birthday = {month: '1'}
      assert_equal [@user], @search.results
    end

    should 'return person matching the birthday month and day' do
      @search.birthday = {month: '1', day: '1'}
      assert_equal [@user], @search.results
    end

    should 'not return person if birthday is not matched' do
      @search.birthday = {month: '1', day: '2'}
      assert_equal [], @search.results
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
      assert_equal [@user], @search.results
    end

    should 'return person matching the anniversary month' do
      @search.anniversary = {month: '2'}
      assert_equal [@user], @search.results
    end

    should 'return person matching the anniversary month and day' do
      @search.anniversary = {month: '2', day: '2'}
      assert_equal [@user], @search.results
    end

    should 'not return person if anniversary is not matched' do
      @search.anniversary = {month: '2', day: '3'}
      assert_equal [], @search.results
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
      assert_equal [@user], @search.results
    end

    should 'return person matching the address state' do
      @search.address = {state: 'OK'}
      assert_equal [@user], @search.results
    end

    should 'return person matching the address zip' do
      @search.address = {zip: '74010'}
      assert_equal [@user], @search.results
    end

    should 'not return person if address does not match' do
      @search.address = {city: 'Tulsa', state: 'AR', zip: '74011'}
      assert_equal [], @search.results
    end
  end

  context 'search by type' do
    setup do
      @search = Search.new
    end

    should 'return members' do
      @search.type = 'member'
      assert_equal [], @search.results
      @user.member = true
      @user.save!
      assert_equal [@user], @search.results.reload
    end

    should 'return staff' do
      @search.type = 'staff'
      assert_equal [], @search.results
      @user.staff = true
      @user.save!
      assert_equal [@user], @search.results.reload
    end

    should 'return elder' do
      @search.type = 'elder'
      assert_equal [], @search.results
      @user.elder = true
      @user.save!
      assert_equal [@user], @search.results.reload
    end
  end

  context 'search by gender' do
    setup do
      @search = Search.new
      @user.gender = 'Female'
      @user.save!
    end

    should 'return males' do
      @search.gender = 'Male'
      assert_equal [@nobody], @search.results
    end

    should 'return females' do
      @search.gender = 'Female'
      assert_equal [@user], @search.results
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
        assert_equal [], @search.results
      end

      context 'user is admin and show_hidden is true' do
        setup do
          @user.admin = Admin.create(view_hidden_profiles: true)
        end

        should 'return child' do
          @search.name = 'mac'
          @search.show_hidden = true
          assert_equal [@child], @search.results
        end
      end
    end

    context 'child has parental consent' do
      setup do
        @child.parental_consent = 'John Smith 1/1/2014'
        @child.save!
      end

      should 'return child' do
        @search.name = 'mac'
        assert_equal [@child], @search.results
      end
    end
  end

  context 'search for families' do
    setup do
      @search = Search.new(source: :family)
    end

    should 'return matching families by name' do
      @search.family_name = 'Smith'
      assert_equal [@user.family], @search.results
    end

    should 'return matching families by barcode id' do
      @user.family.barcode_id = '1234567890'
      @user.family.save!
      @search.family_barcode_id = '1234567890'
      assert_equal [@user.family], @search.results
    end
  end

  context 'search for businesses' do
    setup do
      @search = Search.new(business: true)
      @business = FactoryGirl.create(:person, :with_business)
    end

    should 'return only businesses' do
      assert_equal [@business], @search.results
    end
  end
end
