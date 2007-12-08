# Comatose::Page attributes
#  - parent_id
#  - title
#  - full_path
#  - slug
#  - keywords
#  - body
#  - author
#  - filter_type
#  - position
#  - version
#  - updated_on
#  - created_on
class Comatose::Page < ActiveRecord::Base
  
  set_table_name 'comatose_pages'
  
  # Only versions the content... Not all of the meta data or position
  acts_as_versioned :if_changed => [:title, :slug, :keywords, :body]
  
  define_option :active_mount_info, {:root=>'', :index=>''}

  acts_as_tree :order => "position, title"
  acts_as_list :scope=>:parent_id

  #before_create :create_full_path
  before_save :cache_full_path, :create_full_path
  after_save :update_children_full_path

  # Using before_validation so we can default the slug from the title
  before_validation do |record|
    # Create slug from title
    if (record[:slug].nil? or record[:slug].empty?) and !record[:title].nil?
      record[:slug] = record[:title].downcase.gsub( /[^-a-z0-9~\s\.:;+=_]/, '').gsub(/[\s\.:;=_+]+/, '-').gsub(/[\-]{2,}/, '-').to_s
    end
  end
  
  # Manually set these, because record_timestamps = false
  before_create do |record|
    record[:created_on] = record[:updated_on] = Time.now
  end

  validates_presence_of :title, :on => :save, :message => "must be present"
  validates_uniqueness_of :slug, :on => :save, :scope=>'parent_id', :message => "is already in use"
  validates_presence_of :parent_id, :on=>:create, :message=>"must be present"

  # Tests ERB/Liquid content...
  validates_each :body do |record, attr, value|
    unless value.nil?
      begin
        body_html = record.to_html
      rescue SyntaxError
        record.errors.add :body, "content error: #{$!.to_s.gsub('<', '&lt;')}"
      rescue 
        record.errors.add :body, "content error: #{$!.to_s.gsub('<', '&lt;')}"
      end
    end
  end
    
  # Returns a pages URI dynamically, based on the active mount point
  def uri
    if full_path == ''
      active_mount_info[:root]
    else
      page_path = (full_path || '').split('/')
      idx_path = active_mount_info[:index].split('/')
      uri_root = active_mount_info[:root].split('/')
      uri_path = ( uri_root + (page_path - idx_path) ).flatten.delete_if {|i| i == "" }
      ['',uri_path].join('/')
    end
  end
  
  # Check if a page has a selected keyword... NOT case sensitive. 
  # So the keyword McCray is the same as mccray
  def has_keyword?(keyword)
     begin
       @key_list ||= (self[:keywords] || '').downcase.split(',').map {|k| k.strip }
       @key_list.include? keyword.to_s.downcase
     rescue
       false
     end
   end

  # Returns the page's content, transformed and filtered...
  def to_html(options={})
    #version = options.delete(:version)
    text = self[:body]
    binding = Comatose::ProcessingContext.new(self, options)
    filter_type = self[:filter_type] || '[No Filter]'
    TextFilters.transform(text, binding, filter_type, Comatose.config.default_processor)
  end
  
  def breadcrumbs
    links = []
    total = ''
    ('/' + full_path).split('/').each do |part|
      total += part
      links << Comatose::Page.find_by_path(total)
      total += '/'
    end
    links
  end

# Static helpers...
  
  # Returns a Page with a matching path.
  def self.find_by_path( path )
     path = path.split('.')[0] unless path.empty? # Will ignore file extension...
     path = path[1..-1] if path.starts_with? "/"
     find( :first, :conditions=>[ 'full_path = ?', path ] )
  end
  
# Overrides...

  # I don't want the AR magic timestamping support for this class...
  def record_timestamps
    false
  end
  def self.record_timestamps
    false
  end
  
protected

  # Creates a URI path based on the Page tree
  def create_full_path
     if parent_node = self.parent
        # Build URI Path
        path = "#{parent_node.full_path}/#{self.slug}"
        # strip leading space, if there is one...
        path = path[1..-1] if path.starts_with? "/"
        self[:full_path] = path || ""
     else
        # I'm the root -- My path is blank
        self[:full_path] = ""
     end
  end
  
  # Caches old path (before save) for comparison later
  def cache_full_path
    @old_full_path = self[:full_path]
  end

  # Updates all this content's child URI paths
  def update_children_full_path(should_save=nil)
    # We should only mess with this if the :full_path has changed...
    should_save ||= @old_full_path != self[:full_path] ? true : false
    for child in self.children
      child.create_full_path
      child.save
      child.update_children_full_path(should_save)
    end if should_save
  end
end
