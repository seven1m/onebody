require File.dirname(__FILE__) + '/../test_helper'

class SyncTest < ActiveSupport::TestCase
  
  context 'Associations' do
    
    should 'have many sync items via polymorphic association' do
      @person = Person.forge
      @person2 = Person.forge
      @sync = Sync.create(:person => @person, :complete => true, :success_count => 2, :error_count => 0)
      @sync.sync_items.create(:syncable_type => 'Person', :syncable_id => @person2.id)
      @sync.sync_items.create(:syncable_type => 'Family', :syncable_id => @person2.family_id)
      assert_equal [@person2], @sync.people.all
      assert_equal @person2, @sync.sync_items.first.syncable
      assert_equal [@person2.family], @sync.families.all
    end
    
  end
  
end
