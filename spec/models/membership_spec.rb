require 'rails_helper'

describe Membership, type: :model do
  let(:group)      { FactoryGirl.create(:group) }
  let(:person)     { FactoryGirl.create(:person) }
  let(:membership) { group.memberships.create!(person: person, admin: true) }

  describe '#only_admin?' do
    context 'member is the only admin' do
      let(:membership) { group.memberships.create!(person: person, admin: true) }

      it 'returns true' do
        expect(membership.only_admin?).to eq(true)
      end
    end

    context 'member is the one of two admins' do
      let(:membership)   { group.memberships.create!(person: person, admin: true) }
      let(:person2)      { FactoryGirl.create(:person) }
      let!(:membership2) { group.memberships.create!(person: person2, admin: true) }

      it 'returns false' do
        expect(membership.only_admin?).to eq(false)
      end
    end

    context 'member is not an admin' do
      let(:membership)   { group.memberships.create!(person: person) }

      it 'returns false' do
        expect(membership.only_admin?).to eq(false)
      end
    end
  end
end
