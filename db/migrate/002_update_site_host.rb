class UpdateSiteHost < ActiveRecord::Migration
  def self.up
    require 'highline/import'
    Setting.delete('Contact', 'Group Address Domains')
    to_update = Site.find(:all).select { |s| s.host.to_s.empty? }
    if to_update.any?
      puts 'Each site you configure this installation of OneBody to host must have its host'
      puts 'name set. Do not include www in the hostname. It should look something like'
      puts 'this (without the quotes): "example.com"'
      puts
      puts 'For an install of OneBody serving more than one site (rake multisite:on),'
      puts 'this setting determines the site to serve up based on the URL.'
      puts
      puts 'The host name also affects acceptance and processing of incoming email, even'
      puts 'for installs only serving one site (rake multisite:off).'
      puts
    end
    to_update.each do |site|
      host = ask("For the #{site.name} site, specify the host name: ")
      site.update_attribute :host, host
    end
  end
  
  def self.down
    raise 'Cannot migrate down.'
  end
end
