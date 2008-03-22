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
  SETTINGS_YAML_FILE = File.join(RAILS_ROOT, 'test/fixtures/settings.yml')
  
  class << self
    def sub_tables
      rejects = %w(site search notifier barcode one_body_info)
      @@sub_tables ||= Dir[File.join(File.dirname(__FILE__), '*.rb')].to_a.map { |f| File.split(f).last.split('.').first }.select { |f| !rejects.include? f }.map { |f| f.pluralize }
    end
    def sub_models
      @@sub_models ||= sub_tables.map { |t| eval(t.classify) }
    end
  end
  
  Site.sub_tables.each { |n| has_many n, :dependent => :destroy }
  
  cattr_accessor :current
  
  validates_presence_of :name, :host
  validates_uniqueness_of :name, :host
  
  def multisite_host
    if Setting.get(:features, :multisite)
      host
    else
      id == 1 ? '(any)' : '(none)'
    end
  end
  
  def noreply_email
    "noreply@#{self.host}"
  end
  
  def visible_name
    settings.find_by_section_and_name('Name', 'Site').value rescue nil
  end
  
  def count_people
    connection.select_value("SELECT count(*) from people where site_id=#{id}").to_i
  end
  
  after_create :add_settings
  
  def add_settings
    settings = YAML::load(File.open(SETTINGS_YAML_FILE))
    settings.each do |fixture, values|
      next if values['global']
      unless Setting.find_by_site_id_and_section_and_name(self.id, values['section'], values['name'])
        values.update 'site_id' => self.id
        Setting.create(values)
      end
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
