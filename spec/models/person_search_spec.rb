require_relative '../rails_helper'

describe PersonSearch do
  let(:other_family) { FactoryGirl.create(:family, name: 'Jack Jones', last_name: 'Jones') }
  let(:other_person) { FactoryGirl.create(:person, first_name: 'Jack', last_name: 'Jones', family: other_family) }

  let!(:user) { FactoryGirl.create(:person) }

  before { Person.logged_in = user }

  it 'does not return deleted people' do
    @deleted = FactoryGirl.create(:person, deleted: true)
    expect(PersonSearch.new.results).to_not include(@deleted)
  end

  it 'does not return people from deleted families' do
    @deleted_family = FactoryGirl.create(:family, deleted: true)
    @person = FactoryGirl.create(:person, family: @deleted_family)
    expect(PersonSearch.new.results).to_not include(@person)
  end

  it 'returns people in alphabetical order by last, first' do
    @a = FactoryGirl.create(:person, first_name: 'a', last_name: 'a')
    @z = FactoryGirl.create(:person, first_name: 'z', last_name: 'z')
    expect(PersonSearch.new.results.first).to eq(@a)
    expect(PersonSearch.new.results.last).to eq(@z)
  end

  context 'search by name' do
    let!(:family)  { FactoryGirl.create(:family, name: 'Jack & Jane Jones', last_name: 'Jones') }
    let!(:person1) { FactoryGirl.create(:person, first_name: 'Jack', last_name: 'Jones', family: family) }
    let!(:person2) { FactoryGirl.create(:person, first_name: 'Jane', last_name: 'Jones', family: family) }

    it 'returns person matching the first name' do
      subject.name = 'Jack'
      expect(subject.results).to eq([person1])
    end

    it 'returns people matching the last name' do
      subject.name = 'Jones'
      expect(subject.results).to eq([person1, person2])
    end

    it 'returns person matching the full name' do
      subject.name = 'Jane Jones'
      expect(subject.results).to eq([person2])
    end

    it 'returns none if no name matches' do
      subject.name = 'Jackie Jones'
      expect(subject.results).to eq([])
    end

    it 'returns person matching first part of each name' do
      subject.name = 'Jac Jo'
      expect(subject.results).to eq([person1])
    end

    it 'returns people based on family name' do
      subject.name = 'Jack & Jane Jones'
      expect(subject.results).to eq([person1, person2])
      subject.name = 'Jack and Jane Jones'
      subject.reset
      expect(subject.results).to eq([person1, person2])
    end
  end

  context 'search by birthday' do
    before do
      user.birthday = Date.new(1980, 1, 1)
      user.save!
    end

    it 'returns person matching the birthday day' do
      subject.birthday = {day: '1'}
      expect(subject.results).to eq([user])
    end

    it 'returns person matching the birthday month' do
      subject.birthday = {month: '1'}
      expect(subject.results).to eq([user])
    end

    it 'returns person matching the birthday month and day' do
      subject.birthday = {month: '1', day: '1'}
      expect(subject.results).to eq([user])
    end

    it 'does not return person if birthday is not matched' do
      subject.birthday = {month: '1', day: '2'}
      expect(subject.results).to eq([])
    end
  end

  context 'search by anniversary' do
    before do
      user.anniversary = Date.new(1990, 2, 2)
      user.save!
    end

    it 'returns person matching the anniversary day' do
      subject.anniversary = {day: '2'}
      expect(subject.results).to eq([user])
    end

    it 'returns person matching the anniversary month' do
      subject.anniversary = {month: '2'}
      expect(subject.results).to eq([user])
    end

    it 'returns person matching the anniversary month and day' do
      subject.anniversary = {month: '2', day: '2'}
      expect(subject.results).to eq([user])
    end

    it 'does not return person if anniversary is not matched' do
      subject.anniversary = {month: '2', day: '3'}
      expect(subject.results).to eq([])
    end
  end

  context 'search by address' do
    before do
      user.family.address1 = '123 S. Street'
      user.family.city = 'Tulsa'
      user.family.state = 'OK'
      user.family.zip = '74010'
      user.family.save!
    end

    it 'returns person matching the address city' do
      subject.address = {city: 'Tulsa'}
      expect(subject.results).to eq([user])
    end

    it 'returns person matching the address state' do
      subject.address = {state: 'OK'}
      expect(subject.results).to eq([user])
    end

    it 'returns person matching the address zip' do
      subject.address = {zip: '74010'}
      expect(subject.results).to eq([user])
    end

    it 'does not return person if address does not match' do
      subject.address = {city: 'Tulsa', state: 'AR', zip: '74011'}
      expect(subject.results).to eq([])
    end
  end

  context 'search by type' do
    it 'returns members' do
      subject.type = 'member'
      expect(subject.results).to eq([])
      user.member = true
      user.save!
      expect(subject.results.reload).to eq([user])
    end

    it 'returns staff' do
      subject.type = 'staff'
      expect(subject.results).to eq([])
      user.staff = true
      user.save!
      expect(subject.results.reload).to eq([user])
    end

    it 'returns elder' do
      subject.type = 'elder'
      expect(subject.results).to eq([])
      user.elder = true
      user.save!
      expect(subject.results.reload).to eq([user])
    end
  end

  context 'search by gender' do
    before do
      user.gender = 'Female'
      user.save!
    end

    it 'returns males' do
      subject.gender = 'Male'
      expect(subject.results).to eq([other_person])
    end

    it 'returns females' do
      subject.gender = 'Female'
      expect(subject.results).to eq([user])
    end
  end

  context 'search by group membership' do
    subject { PersonSearch.new(group_category: 'Fellowship') }

    before do
      @group = FactoryGirl.create(:group, name: 'Housegroup', category: 'Fellowship')
    end

    it 'returns user belonging to group' do
      subject.group_category = 'Fellowship'
      subject.group_select_option = '1'
      expect(subject.results).to eq([])
      user.groups << @group
      user.save!
      expect(subject.results.reload).to eq([user])
    end

    it 'does not return user who is not a group member' do
      subject.group_category = 'Fellowship'
      subject.group_select_option = '0'
      expect(subject.results).to eq([other_person, user])
      user.groups << @group
      user.save!
      expect(subject.results.reload).to eq([other_person])
    end
  end

  context 'given a child' do
    before do
      @child = FactoryGirl.create(:person, first_name: 'Mac', child: true)
    end

    context 'child does not have parental consent' do
      it 'does not return child' do
        subject.name = 'mac'
        expect(subject.results).to eq([])
      end

      context 'user is admin and show_hidden is true' do
        before do
          user.admin = Admin.create(view_hidden_profiles: true)
        end

        it 'returns child' do
          subject.name = 'mac'
          subject.show_hidden = true
          expect(subject.results).to eq([@child])
        end
      end
    end

    context 'child has parental consent' do
      before do
        @child.parental_consent = 'John Smith 1/1/2014'
        @child.save!
      end

      it 'returns child' do
        subject.name = 'mac'
        expect(subject.results).to eq([@child])
      end
    end
  end

  context 'search for businesses' do
    subject { PersonSearch.new(business: true) }

    before do
      @business = FactoryGirl.create(:person, :with_business)
    end

    it 'returns only businesses' do
      expect(subject.results).to eq([@business])
    end
  end
end
