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
#  twitter_enabled       :boolean
#  external_guid         :string(255)   default("0")
#

class Site < ActiveRecord::Base

  class << self
    def sub_tables
      rejects = %w(site search notifier one_body_info tagging signin_failure)
      @@sub_tables ||= Dir[File.join(File.dirname(__FILE__), '*.rb')].to_a.map { |f| File.split(f).last.split('.').first }.select { |f| !rejects.include? f }.map { |f| f.pluralize }
    end
    def sub_models
      @@sub_models ||= sub_tables.map { |t| eval(t.classify) }
    end
  end

  Site.sub_tables.each { |n| has_many n, :dependent => :delete_all }

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

  after_update :update_url

  def update_url
    if setting = self.settings.find_by_section_and_name('URL', 'Site')
      setting.update_attributes!(:value => "http://#{host}/")
    end
  end

  after_create :add_settings, :add_pages, :add_publications_group

  def add_settings
    Setting.update_site(self)
    update_url
  end

  def add_pages
    return unless Page.table_exists?
    Page.without_global_scope do
      Dir["#{Rails.root}/db/pages/**/index.html"].each do |filename|
        html = File.read(filename)
        path, filename = filename.split('pages/').last.split('/')
        pub = nav = path != 'system'
        unless self.pages.find_by_path(path)
          self.pages.create!(:slug => path, :title => path.titleize, :body => html, :system => true, :navigation => nav, :published => pub)
        end
      end
      Dir["#{Rails.root}/db/pages/**/*.html"].each do |filename|
        next if filename =~ /index\.html$/
        html = File.read(filename)
        path, filename = filename.split('pages/').last.split('/')
        slug = filename.split('.').first
        nav = path != 'system'
        pub = !Page::UNPUBLISHED_PAGES.include?(slug)
        parent = self.pages.find_by_path(path)
        unless parent.children.find_by_slug(slug)
          page = parent.children.build(:slug => slug, :title => slug.titleize, :body => html, :system => true, :navigation => nav, :published => pub)
          page.site_id = self.id
          page.save!
        end
      end
      unless self.pages.find_by_path('home')
        self.pages.create!(:slug => 'home', :title => 'Home', :body => 'Congratulations! OneBody is up and running.', :system => true)
      end
    end
  end

  def add_publications_group
    was = Site.current
    Site.current = self
    group = Group.new(:name => 'Publications', :description => 'People who wish to be notified when new publications become available on the website.', :category => 'Subscription', :address => 'publications', :members_send => false, :approved => true, :hidden => true)
    group.save(false)
    Site.current = was
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
