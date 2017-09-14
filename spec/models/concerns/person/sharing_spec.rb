require 'rails_helper'

describe Concerns::Person::Sharing do
  before do
    @person = FactoryGirl.create(:person)
    @group = FactoryGirl.create(:group)
  end

  describe '#small_groups' do
    context 'small group defined as 5 or fewer' do
      before do
        Setting.set(:features, :small_group_size, 5)
      end

      context 'group with one person in it' do
        before do
          @group.memberships.create(person: @person)
        end

        it 'is returned' do
          expect(@person.small_groups).to include(@group)
        end
      end

      context 'group with 5 people in it' do
        before do
          @group.memberships.create(person: @person)
          # fake 4 more memberships
          4.times { @group.memberships.create!(person: FactoryGirl.create(:person)) }
        end

        it 'is returned' do
          expect(@person.small_groups).to include(@group)
        end
      end

      context 'group with 6 people in it' do
        before do
          @group.memberships.create(person: @person)
          # fake 5 more memberships
          5.times { @group.memberships.create!(person: FactoryGirl.create(:person)) }
        end

        it 'is not returned' do
          expect(@person.small_groups).to_not include(@group)
        end
      end
    end

    context 'small group defined as "any"' do
      before do
        Setting.set(:features, :small_group_size, 'all')
        @group.memberships.create(person: @person)
      end

      it 'is returned' do
        expect(@person.small_groups).to include(@group)
      end
    end
  end
end
