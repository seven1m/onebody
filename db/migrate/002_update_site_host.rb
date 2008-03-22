class UpdateSiteHost < ActiveRecord::Migration
  def self.up
    Setting.delete('Contact', 'Group Address Domains')
  end
  
  def self.down
    raise 'Cannot migrate down.'
  end
end
