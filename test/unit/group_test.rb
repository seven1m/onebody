require "#{File.dirname(__FILE__)}/../test_helper"

class GroupTest < ActiveSupport::TestCase
  def setup
    @person = Person.logged_in = Person.forge
    @group = Group.forge(:creator_id => @person.id, :category => 'Small Groups')
    2.times { Group.forge(:category => 'foo') }
    Group.forge(:category => 'bar', :hidden => true)
  end

  should "list all group categories" do
    cats = Group.categories
    assert_equal 2, cats.keys.length
    assert_equal 2, cats['Small Groups']
    assert_equal 2, cats['foo']
    assert cats['bar'].nil?
    assert cats['Subscription'].nil?
  end
  
  should "list all group categories including hidden and pending approval if user can manage groups" do
    @person.admin = Admin.create(:manage_groups => true); @person.save
    cats = Group.categories
    assert_equal 3, cats.keys.length
    assert_equal 3, cats['Small Groups']
    assert_equal 2, cats['foo']
    assert_equal 1, cats['bar']
    assert cats['Subscription'].nil?
  end
end
