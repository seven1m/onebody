class AddPublicationsGroup < ActiveRecord::Migration
  def self.up
    Group.create :name => 'Publications', :description => 'People who wish to be notified when new publications become available on the website.', :category => 'Subscription', :address => 'publications', :members_send => false, :subscription => true
  end

  def self.down
    Group.find_by_name('Publications').destroy
  end
end
