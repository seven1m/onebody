require_relative '../test_helper'

class UpdateTest < ActiveSupport::TestCase

  context 'apply' do
    setup do
      @person = FactoryGirl.create(:person)
      @update = @person.updates.create!(data: {
        person: {
          first_name: 'Tim',
          birthday: Date.new(2000, 1, 1)
        },
        family: {
          name: 'Tim Smith'
        }
      })
      assert @update.apply!
    end

    should 'update the person' do
      assert_equal 'Tim', @person.reload.first_name
    end

    should 'update the person birthday' do
      assert_equal Time.utc(2000, 1, 1), @person.reload.birthday
    end

    should 'update the family' do
      assert_equal 'Tim Smith', @person.family.reload.name
    end

    context 'birthday of nil' do
      setup do
        @update.data[:person][:birthday] = nil
        @update.data[:person][:child] = false
        assert @update.apply!
      end

      should 'update the person birthday to nil' do
        assert_equal nil, @person.reload.birthday
      end
    end
  end

end
