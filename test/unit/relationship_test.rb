require File.dirname(__FILE__) + '/../test_helper'

class RelationshipTest < ActiveSupport::TestCase
  
  should "not allow an invalid relationship name" do
    relationship = Relationship.new(
      :name    => 'junk',
      :person  => people(:tim),
      :related => people(:jeremy)
    )
    assert !relationship.valid?
    assert relationship.errors.on(:name)
  end
  
  should "allow a valid relationship name" do
    relationship = Relationship.new(
      :name    => 'uncle',
      :person  => people(:tim),
      :related => people(:jeremy)
    )
    assert relationship.valid?
  end
  
  should "reciprocate certain relationship names" do
    relationship = Relationship.create!(
      :name    => 'mother_in_law',
      :person  => Person.forge(:gender => 'Male'),
      :related => Person.forge(:gender => 'Female')
    )
    assert relationship.can_auto_reciprocate?
    assert_equal 'son_in_law', relationship.reciprocal_name
  end
  
  should "not reciprocate certain relationship names" do
    relationship = Relationship.create!(
      :name       => 'other',
      :other_name => 'Friend',
      :person     => people(:tim),
      :related    => people(:jeremy)
    )
    assert !relationship.can_auto_reciprocate?
    assert_equal nil, relationship.reciprocal_name
  end
  
end
