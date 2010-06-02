require File.dirname(__FILE__) + '/../test_helper'

class PrayerRequestTest < ActiveSupport::TestCase

  def setup
    @group = Group.forge
    @person = Person.forge
    @req = PrayerRequest.forge(:group => @group, :person => @person)
  end

  should "have a name" do
    assert_equal "Prayer Request in #{@group.name}", @req.name
  end

  should "have a name with a question mark if the group doesn't exist" do
    @group.destroy # does not destroy child prayer requests
    @req.reload
    assert_equal "Prayer Request in ?", @req.name
  end

end
