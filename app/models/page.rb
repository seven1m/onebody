class Page < ApplicationRecord
  include Authority::Abilities
  self.authorizer_name = 'PageAuthorizer'

  belongs_to :parent, class_name: 'Page'
  has_many :children, class_name: 'Page', foreign_key: 'parent_id', dependent: :destroy
  belongs_to :site

  scope_by_site_id

  validates_presence_of :slug, :title, :body
  validates_uniqueness_of :path, scope: :site_id
  validates_exclusion_of :slug, in: %w(admin edit new)
  validates_format_of :slug, with: /\A[a-z0-9][a-z0-9_]*\z/

  before_save :update_path

  def update_path
    self.path = if parent
                  parent.path + '/' + slug
                else
                  slug
                end
  end

  def name
    title
  end

  def home?
    path == 'home'
  end

  def body
    if cooked = read_attribute(:body).dup
      cooked.gsub!(/(%5B%5B|\[\[)([a-z_]+)%7C([a-z_]+)(%5D%5D|\]\])/, '[[\\2|\\3]]')
      cooked.gsub(/\[\[([a-z_]+)\|([a-z_]+)\]\]/) do
        begin
          Setting.get(Regexp.last_match(1).to_sym, Regexp.last_match(2).to_sym).to_s
        rescue
          '???'
        end
      end
    end
  end

  def navigation_pages
    if home?
      Page.root_pages
    else
      children.where(published: true, navigation: true)
    end
  end

  def for_members?
    path =~ /^system\//
  end

  before_destroy :cannot_destroy_system_page

  def cannot_destroy_system_page
    return unless system?
    errors.add(:base, 'Cannot delete system pages.')
    throw :abort
  end

  class << self
    def find(id, *args)
      if id.is_a?(String) && id !~ /^\d+$/
        find_by_path(id).tap do |page|
          raise ActiveRecord::RecordNotFound unless page
        end
      else
        super
      end
    end

    def find_by_id_or_path(id_or_path)
      if id_or_path.is_a?(String) && id_or_path !~ /^\d+$/
        where(path: id_or_path).first
      else
        where(id: id_or_path).first
      end
    end

    def find_by_path(path)
      where(path: normalize_path(path)).first
    end

    def normalize_path(path)
      path = home_if_blank(path)
      path.sub(%r{^/}, '').sub(%r{/$}, '').gsub(%r{//}, '/').gsub(/\s/, '').downcase
    end

    def home_if_blank(path)
      path.to_s.empty? ? 'home' : path
    end

    def paths_and_ids
      connection.select_all("select path, id from pages where path != '' and site_id = #{Site.current.id} order by path").map { |r| [r['path'], r['id'].to_i] }
    end

    def root_pages(include_home = false, published = true, navigation = true)
      Page.where(parent_id: nil, published: published, navigation: navigation).to_a.select { |p| include_home || !p.home? }
    end
  end
end
