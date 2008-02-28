class UpdateSiteHost < ActiveRecord::Migration
  def self.up
    require 'highline/import'
    Setting.delete('Contact', 'Group Address Domains')
    Site.find(:all).select { |s| s.host.to_s.empty? }.each do |site|
      host = ask("For the #{site.name} site, specify the host name: ")
      site.update_attribute :host, host
    end
  end
  
  def self.down
    raise 'Cannot migrate down.'
  end
end
