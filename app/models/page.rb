# == Schema Information
# Schema version: 20080715223033
#
# Table name: pages
#
#  id         :integer       not null, primary key
#  slug       :string(255)   
#  title      :string(255)   
#  body       :text          
#  parent_id  :integer       
#  path       :string(255)   
#  published  :boolean       default(TRUE)
#  site_id    :integer       
#  created_at :datetime      
#  updated_at :datetime      
#

class Page < ActiveRecord::Base
  belongs_to :parent, :class_name => 'Page'
  has_many :children, :class_name => 'Page', :foreign_key => 'parent_id'
  has_many :attachments
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  acts_as_logger LogItem
  
  validates_presence_of :slug, :title, :body
  validates_uniqueness_of :path
  validates_exclusion_of :slug, :in => %w(admin edit new)
  validates_format_of :slug, :with => /^[a-z_]+$/
  
#  def slug=(s)
#    write_attribute :slug, s.downcase.scan(/[a-z_]/).join
#  end
  
  before_save :update_path
  
  def update_path
    if parent
      self.path = parent.path + '/' + slug
    else
      self.path = slug
    end
  end
  
  class << self
    
    def find(id, *args)
      if id.is_a?(String) and id !~ /\d/
        returning find_by_path(id) do |page|
          raise ActiveRecord::RecordNotFound unless page
        end
      else
        super
      end
    end
    
    def find_by_path(path)
      find(:first, :conditions => ['path = ?', normalize_path(path)])
    end
    
    def normalize_path(path)
      path = home_if_blank(path)
      path.sub(%r{^/}, '').sub(%r{/$}, '').gsub(%r{//}, '/').gsub(/\s/, '').downcase
    end
    
    def home_if_blank(path)
      path.to_s.empty? ? 'home' : path
    end
    
    def paths_and_ids
      connection.select_all("select path, id from pages where path != '' order by path").map { |r| [r['path'], r['id'].to_i] }
    end
  
  end
end
