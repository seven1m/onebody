# == Schema Information
# Schema version: 4
#
# Table name: sites
#
#  id         :integer       not null, primary key
#  name       :string(255)   
#  host       :string(255)   
#  created_at :datetime      
#  updated_at :datetime      
#

class Site < ActiveRecord::Base
  class << self
    def sub_tables
      rejects = %w(sites searches notifiers barcodes)
      @@sub_tables ||= Dir[File.join(File.dirname(__FILE__), '*.rb')].to_a.map { |f| File.split(f).last.split('.').first.pluralize }.select { |f| !rejects.include? f }
    end
    def sub_models
      @@sub_models ||= sub_tables.map { |t| eval(t.classify) }
    end
  end
  
  Site.sub_tables.each { |n| has_many n, :dependent => :destroy }
  
  cattr_accessor :current
  
  validates_uniqueness_of :name, :host
  
  def noreply_email
    "noreply@#{self.host}"
  end
  
  def visible_name
    settings.find_by_section_and_name('Name', 'Site').value
  end
  
  after_create :duplicate_settings
  
  def duplicate_settings
    if self.id != 1 and self.settings.count == 0
      Setting.find_all_by_site_id(1).each { |s| s.clone.update_attributes! :site_id => self.id }
    end
  end
  
  alias_method :rails_original_destroy, :destroy
  def destroy
    raise 'This is such a destructive method that it has been renamed to destroy_for_sure for your safety.'
  end
  def destroy_for_sure
    raise 'You cannot delete the default site (ID=1).' if self.id == 1
    rails_original_destroy
  end
end
