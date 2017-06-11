require_relative '../rails_helper'

describe Relationship do
  before do
    @person = FactoryGirl.create(:person)
    @related = FactoryGirl.create(:person)
  end

  it 'should not allow an invalid relationship name' do
    relationship = Relationship.new(
      name:    'junk',
      person:  @person,
      related: @related
    )
    expect(relationship).to_not be_valid
    expect(relationship.errors[:name]).to be
  end

  it 'should allow a valid relationship name' do
    relationship = Relationship.new(
      name:    'uncle',
      person:  @person,
      related: @related
    )
    expect(relationship).to be_valid
  end

  it 'should reciprocate certain relationship names' do
    relationship = Relationship.create!(
      name:    'mother_in_law',
      person:  @person,
      related: @related
    )
    expect(relationship).to be_can_auto_reciprocate
    expect(relationship.reciprocal_name).to eq('son_in_law')
  end

  it 'should not reciprocate certain relationship names' do
    relationship = Relationship.create!(
      name:       'other',
      other_name: 'Friend',
      person:     @person,
      related:    @related
    )
    expect(relationship).to_not be_can_auto_reciprocate
    expect(relationship.reciprocal_name).to eq(nil)
  end
end
