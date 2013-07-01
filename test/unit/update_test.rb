require_relative '../test_helper'

class UpdateTest < ActiveSupport::TestCase

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
  end

  context '#save!' do
    setup do
      @update.data = ActionController::Parameters.new(
        'person' => ActionController::Parameters.new(@update.data[:person])
      )
      @update.save!
    end

    should 'convert ActionController::Parameters to a Hash' do
      assert_equal Hash, @update.reload.data.class
      assert_equal Hash, @update.data[:person].class
    end

    should 'ensure top level key is symbol' do
      assert_equal [:person], @update.reload.data.keys
    end
  end

  context '#apply!' do
    setup do
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
        @update.update_attributes!(complete: false)
        @update.data[:person][:birthday] = nil
        @update.data[:person][:child] = false
        assert @update.apply!
      end

      should 'update the person birthday to nil' do
        assert_equal nil, @person.reload.birthday
      end
    end
  end

  context '#require_child_designation?' do
    setup do
      @update.data[:person][:birthday] = nil
    end

    context 'birthday unchanged and already a child' do
      setup do
        @update.person.update_attributes!(
          birthday: nil,
          child: true
        )
      end

      should 'return false' do
        assert_equal false, @update.require_child_designation?
      end
    end

    context 'birthday unchanged and already not a child' do
      setup do
        @update.person.update_attributes!(
          birthday: nil,
          child: false
        )
      end

      should 'return false' do
        assert_equal false, @update.require_child_designation?
      end
    end

    context 'removing birthday with no child designation' do
      setup do
        @update.person.update_attributes!(
          birthday: Date.new(2000, 1, 1),
          child: nil
        )
      end

      should 'return true' do
        assert_equal true, @update.require_child_designation?
      end
    end
  end

  context '#diff' do
    setup do
      @expected = {
        'person' => {
          'first_name' => ['John', 'Tim'],
          'birthday' => [nil, Date.new(2000, 1, 1)],
        },
        'family' => {
          'name' => ['John Smith', 'Tim Smith']
        }
      }
    end

    context 'before applied' do
      should 'return a hash of changed keys and values' do
        assert_equal @expected, @update.diff
      end
    end

    context 'after applied' do
      setup do
        @update.apply!
      end

      should 'return a hash of changed keys and values' do
        assert_equal @expected, @update.diff
      end
    end

    context 'legacy update record' do
      setup do
        @update.diff = {}
        @update.complete = true
        @update.save!
      end

      should 'have no stored diff' do
        assert_empty @update.send(:read_attribute, :diff)
      end

      should 'show a diff with question marks' do
        expected = {
          'person' => {
            'first_name' => [:unknown, 'Tim'],
            'birthday' => [:unknown, Date.new(2000, 1, 1)]
          },
          'family' => {
            'name' => [:unknown, 'Tim Smith']
          }
        }
        assert_equal expected, @update.diff
      end
    end
  end

  context 'apply attribute' do
    should 'apply the update' do
      @update.update_attributes!(apply: true)
      assert_equal 'Tim', @person.reload.first_name
    end
  end

end
