require_relative '../rails_helper'

describe Update, type: :model do
  before do
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
    before do
      @update.data = ActionController::Parameters.new(
        'person' => ActionController::Parameters.new(@update.data[:person])
      )
      @update.save!
    end

    it 'should convert ActionController::Parameters to a Hash' do
      expect(@update.reload.data.class).to eq(Hash)
      expect(@update.data[:person].class).to eq(Hash)
    end

    it 'should ensure top level key is symbol' do
      expect(@update.reload.data.keys).to eq([:person])
    end
  end

  context '#apply!' do
    before do
      expect(@update.apply!).to be
    end

    it 'should update the person' do
      expect(@person.reload.first_name).to eq('Tim')
    end

    it 'should update the person birthday' do
      expect(@person.reload.birthday).to eq(Time.utc(2000, 1, 1))
    end

    it 'should update the family' do
      expect(@person.family.reload.name).to eq('Tim Smith')
    end

    context 'birthday of nil' do
      before do
        @update.update_attributes!(complete: false)
        @update.data[:person][:birthday] = nil
        @update.data[:person][:child] = false
        expect(@update.apply!).to be
      end

      it 'should update the person birthday to nil' do
        expect(@person.reload.birthday).to eq(nil)
      end
    end
  end

  context '#require_child_designation?' do
    before do
      @update.data[:person][:birthday] = nil
    end

    context 'birthday unchanged and already a child' do
      before do
        @update.person.update_attributes!(
          birthday: nil,
          child: true
        )
      end

      it 'should return false' do
        expect(@update.require_child_designation?).to eq(false)
      end
    end

    context 'birthday unchanged and already not a child' do
      before do
        @update.person.update_attributes!(
          birthday: nil,
          child: false
        )
      end

      it 'should return false' do
        expect(@update.require_child_designation?).to eq(false)
      end
    end

    context 'removing birthday and already is a child' do
      before do
        @update.person.update_attributes!(
          birthday: Date.new(2000, 1, 1),
          child: true
        )
      end

      it 'should return false' do
        expect(@update.require_child_designation?).to eq(false)
      end
    end
  end

  context '#diff' do
    before do
      @expected = {
        'person' => {
          'first_name' => %w(John Tim),
          'birthday' => [nil, Date.new(2000, 1, 1)]
        },
        'family' => {
          'name' => ['John Smith', 'Tim Smith']
        }
      }
    end

    context 'before applied' do
      it 'should return a hash of changed keys and values' do
        expect(@update.diff).to eq(@expected)
      end
    end

    context 'after applied' do
      before do
        @update.apply!
      end

      it 'should return a hash of changed keys and values' do
        expect(@update.diff).to eq(@expected)
      end
    end

    context 'legacy update record' do
      before do
        @update.diff = {}
        @update.complete = true
        @update.save!
      end

      it 'should have no stored diff' do
        expect(@update.send(:read_attribute, :diff)).to be_empty
      end

      it 'should show a diff with question marks' do
        expected = {
          'person' => {
            'first_name' => [:unknown, 'Tim'],
            'birthday' => [:unknown, Date.new(2000, 1, 1)]
          },
          'family' => {
            'name' => [:unknown, 'Tim Smith']
          }
        }
        expect(@update.diff).to eq(expected)
      end
    end
  end

  context 'apply attribute' do
    it 'should apply the update' do
      @update.update_attributes!(apply: true)
      expect(@person.reload.first_name).to eq('Tim')
    end
  end
end
