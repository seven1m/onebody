# == Schema Information
#
# Table name: log_items
#
#  id             :integer(4)    not null, primary key
#  object_changes :text          
#  person_id      :integer(4)    
#  created_at     :datetime      
#  reviewed_on    :datetime      
#  reviewed_by    :integer(4)    
#  flagged_on     :datetime      
#  flagged_by     :string(255)   
#  deleted        :boolean(1)    
#  name           :string(255)   
#  group_id       :integer(4)    
#  site_id        :integer(4)    
#  loggable_id    :integer(4)    
#  loggable_type  :string(255)   
#

class LogItem < ActiveRecord::Base
  belongs_to :person
  belongs_to :group
  belongs_to :reviewed_by, :class_name => 'Person', :foreign_key => 'reviewed_by'
  belongs_to :site
  belongs_to :loggable, :polymorphic => true
  
  serialize :object_changes
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  
  def object
    self.loggable
  end
  
  def object_description
    return nil unless object
    if object.is_a? Page
      object.path
    elsif object.respond_to?(:name)
      object.name
    elsif object.is_a? Membership
      "#{object.person.name} in group #{object.group.name}" rescue '???'
    else
      object.id
    end
  end
  
  def object_excerpt
    return nil unless object
    case loggable_type
    when 'Message'
      if object.to
        '-private message-'
      else
        truncate(object.body)
      end
    when 'Comment', 'Verse'
      truncate(object.text)
    when 'Recipe'
      truncate(object.description)
    else
      nil
    end
  end
  
  def object_url
    return nil if deleted?
    id = instance_id
    case loggable_type
    when 'Comment'
      object.on
    when 'Family'
      object.people.first
    when 'Membership'
      object.group
    else
      object
    end
  end
  
  def object_image_url
    return nil if deleted?
    return nil unless object.respond_to? 'has_photo?' and object.has_photo?
    controller = loggable_type.pluralize.downcase
    action = 'photo'
    id = "#{instance_id}.tn.jpg"
    "/#{controller}/#{action}/#{id}"
  end
  
  def is_blog_item?
    return false unless %w(Verse Recipe Note Picture).include?(loggable_type)
    # if an admin or another person does something on behalf of someone else, don't count it as a blog item entry
    return false if object.respond_to?(:person_id) and object.person_id != self.person_id
    return false if object.respond_to?(:people)    and !object.person_ids.include?(self.person_id)
    true
  end
  
  # crude way of determining if this is the first log_item for this object
  def created?
    conditions = ["loggable_type = ? and loggable_id = ?", self.loggable_type, self.loggable_id]
    conditions.add_condition(["id < ?", self.id]) unless self.new_record?
    LogItem.count('*', :conditions => conditions) == 0
  end
  
  after_create :create_as_blog_item
  
  def create_as_blog_item
    return unless is_blog_item?
    return unless created? and !deleted? # only on creation (one BlogItem per object please)
    BlogItem.create!(
      :name           => self.name,
      :body           => object.respond_to?(:body) ? object.body : nil, # body is aliased to text in Verse and description in Recipe
      :album_id       => object.respond_to?(:album_id) ? object.album_id : nil,
      :person_id      => self.person_id,
      :bloggable_type => self.loggable_type,
      :bloggable_id   => self.loggable_id,
      :created_at     => self.created_at
    )
  end
  
  after_destroy :delete_blog_item
  
  def delete_blog_item
    BlogItem.destroy_all(:bloggable_type => self.loggable_type, :bloggable_id => self.loggable_id)
  end
  
  def showable_change_keys
    return [] if deleted?
    begin
      object_changes.keys.select do |key|
        PEOPLE_ATTRIBUTES_SHOWABLE_ON_HOMEPAGE.include? key
      end.map do |key|
        key == 'tv_shows' ? 'TV Shows' : key.split('_').map { |w| w.capitalize }.join(' ')
      end
    rescue NoMethodError # sometimes object_changes doesn't un-serialize. Weird.
      []
    end
  end
  
  private
    def truncate(text, length=30, truncate_string="...")
      return nil unless text
      l = length - truncate_string.length
      chars = text.split(//)
      chars.length > length ? chars[0...l].join + truncate_string : text
    end
    
  class << self
    def flag_suspicious_activity(since=nil)
      conditions = ["loggable_type in ('Message', 'Comment')"]
      if since
        since = Time.now - since.days       if since.is_a?(Fixnum)
        since = Time.now - since.to_i.hours if since.is_a?(String) and since =~ /\d+\shours?/
        conditions.add_condition ["created_at >= ?", since]
      end
      flagged = []
      LogItem.find(:all, :conditions => conditions).each do |log_item|
        if log_item.object
          # flag bad/suspicious words
          body = log_item.object.is_a?(Message) ? log_item.object.body : log_item.object.text
          FLAG_WORDS.each do |word|
            if body =~ word
              log_item.flagged_on = Time.now
              log_item.flagged_by = 'System'
              log_item.save
              flagged << log_item
              break
            end
          end
          if log_item.object.is_a? Message
            # flag suspicious age differences
            from = log_item.object.person
            if to = log_item.object.to || log_item.object.wall
              if (FLAG_AGES[:adult].include? from.years_of_age and FLAG_AGES[:child].include? to.years_of_age) \
                or (FLAG_AGES[:child].include? from.years_of_age and FLAG_AGES[:adult].include? to.years_of_age)
                log_item.flagged_on = Time.now
                log_item.flagged_by = 'System'
                log_item.save
                flagged << log_item
              end
            end
          end
        end
      end
      flagged
    end
  end
end
