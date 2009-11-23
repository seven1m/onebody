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
      :name    => 'aunt',
      :person  => people(:tim),
      :related => people(:jeremy)
    )
    assert relationship.valid?
  end
  
end
