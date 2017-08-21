class Site < ApplicationRecord
  has_many :settings, dependent: :delete_all
  has_one :stream_item, as: :streamable

  def self.current
    Thread.current[:site]
  end

  def self.current=(site)
    Thread.current[:site] = site
  end

  def self.with_current(site)
    was = Thread.current[:site]
    Thread.current[:site] = site
    yield
    Thread.current[:site] = was
  end

  validates_presence_of :name, :host
  validates_uniqueness_of :name, :host
  validates_format_of :host, without: /\A(https?:\/\/|www\.)/

  def create_as_stream_item
    StreamItem.create!(
      title: Setting.get(:name, :community),
      person_id: nil,
      streamable_type: 'Site',
      streamable_id: id,
      created_at: created_at,
      shared: true
    )
  end

  def update_stream_item(person)
    return unless stream_item
    stream_item.person = person
    stream_item.save!
  end

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

  def email_host
    self[:email_host].presence || host
  end

  def noreply_email
    "noreply@#{email_host}"
  end

  def visible_name
    settings.where(section: 'Name', name: 'Site').first.value
  rescue
    nil
  end

  def enabled?
    Setting.get(:features, :multisite) || default?
  end

  after_update :update_url

  def update_url
    return unless (setting = settings.where(section: 'URL', name: 'Site').first)
    scheme = Setting.get(:features, :ssl) ? 'https' : 'http'
    setting.update_attributes!(value: "#{scheme}://#{host}/")
    Setting.precache_settings(true)
  end

  after_create :add_settings, :add_pages

  def add_settings
    Setting.update_site(self)
    update_url
  end

  def add_pages
    was = Site.current
    Site.current = self
    return unless Page.table_exists?
    Dir["#{Rails.root}/db/pages/**/index.html"].each do |filename|
      html = File.read(filename)
      path, filename = filename.split('pages/').last.split('/')
      pub = nav = path != 'system'
      unless Page.where(path: path).first
        Page.create!(slug: path, title: path.titleize, body: html, system: true, navigation: nav, published: pub)
      end
    end
    Dir["#{Rails.root}/db/pages/**/*.html"].each do |filename|
      next if filename =~ /index\.html$/
      html = File.read(filename)
      path, filename = filename.split('pages/').last.split('/')
      slug = filename.split('.').first
      nav = path != 'system'
      parent = Page.where(path: path).first
      next if parent.children.where(slug: slug).first
      page = parent.children.build(
        slug:       slug,
        title:      slug.titleize,
        body:       html,
        system:     true,
        navigation: nav,
        published:  true
      )
      page.site_id = id
      page.save!
    end
    Site.current = was
  end

  alias rails_original_destroy destroy

  def destroy
    raise 'This is such a destructive method that it has been renamed to destroy_for_real for your safety.'
  end

  def destroy_for_real
    raise 'You cannot delete the default site (ID=1).' if default?
    rails_original_destroy
  end

  class << self
    def each
      Site.where(active: true).each do |site|
        Site.current = site
        yield(site)
      end
    end
  end
end
