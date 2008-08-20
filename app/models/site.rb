# == Schema Information
#
# Table name: sites
#
#  id                    :integer       not null, primary key
#  name                  :string(255)   
#  host                  :string(255)   
#  created_at            :datetime      
#  updated_at            :datetime      
#  secondary_host        :string(255)   
#  max_admins            :integer       
#  max_people            :integer       
#  max_groups            :integer       
#  import_export_enabled :boolean       default(TRUE)
#  pages_enabled         :boolean       default(TRUE)
#  pictures_enabled      :boolean       default(TRUE)
#  publications_enabled  :boolean       default(TRUE)
#  active                :boolean       default(TRUE)
#

class Site < ActiveRecord::Base
  SETTINGS_YAML_FILE = File.join(RAILS_ROOT, 'test/fixtures/settings.yml')
  
  class << self
    def sub_tables
      rejects = %w(site search notifier barcode one_body_info twitter_bot tagging highrise)
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
  validates_exclusion_of :host, :in => %w(admin api home onebody)
  
  def default?
    id == 1
  end
  
  def multisite_host
    if Setting.get(:features, :multisite)
      host
    else
      default? ? '(any)' : '(none)'
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
  
  def enabled?
    Setting.get(:features, :multisite) or default?
  end
  
  after_create :add_settings, :add_tasks, :add_pages
  
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
  
  def add_tasks
    return unless ScheduledTask.table_exists?
    [
      {:name => 'Update News Feed',            :command => 'NewsItem.update_from_feed',                  :interval => 'hourly'},
      {:name => 'Update Group Cached Parents', :command => 'Group.update_cached_parents',                :interval => 'hourly'},
      {:name => 'Flag Suspicious Activity',    :command => 'LogItem.flag_suspicious_activity("1 hour")', :interval => 'hourly'},
      {:name     => 'Email Downloader',
       :runner   => false,
       :command  => 'RAILS_ROOT/script/inbox -e RAILS_ENV -s "SITE_NAME" EMAIL_HOST EMAIL_USERNAME EMAIL_PASSWORD',
       :interval => 'minutely',
       :active   => false}
    ].each { |t| self.scheduled_tasks.create!(t) unless self.scheduled_tasks.find_by_name(t[:name]) }
  end
  
  def add_pages
    # FIXME: Move the migration code into a Site #method and quit calling migrations from code!
    site_was = Site.current
    if Page.table_exists?
      require Rails.root + "/db/migrate/20080722143227_move_system_content_to_pages"
      MoveSystemContentToPages.up
    end
    Site.current = site_was
  end
  
  def twitter_enabled?
    @twitter_enabled ||= self.settings.find_by_name('Twitter Account').value.to_s.any? \
      && self.settings.find_by_name('Twitter Password').value.to_s.any?
  end
  
  alias_method :rails_original_destroy, :destroy
  def destroy
    raise 'This is such a destructive method that it has been renamed to destroy_for_sure for your safety.'
  end
  def destroy_for_sure
    raise 'You cannot delete the default site (ID=1).' if default?
    # TO DO: this is messy
    was = Site.current
    Site.current = self
    rails_original_destroy
    Site.current = was
  end
  
  class << self
    def each
      Site.find(:all).each do |site|
        Site.current = site
        yield(site)
      end
    end
  end
end
