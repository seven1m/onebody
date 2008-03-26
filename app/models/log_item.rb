# == Schema Information
# Schema version: 4
#
# Table name: log_items
#
#  id          :integer       not null, primary key
#  name        :string(255)   
#  model_name  :string(50)    
#  instance_id :integer       
#  changes     :text          
#  person_id   :integer       
#  group_id    :integer       
#  created_at  :datetime      
#  reviewed_on :datetime      
#  reviewed_by :integer       
#  flagged_on  :datetime      
#  flagged_by  :string(255)   
#  deleted     :boolean       
#  site_id     :integer       
#

class LogItem < ActiveRecord::Base
  belongs_to :person
  belongs_to :group
  belongs_to :reviewed_by, :class_name => 'Person', :foreign_key => 'reviewed_by'
  belongs_to :site
  
  serialize :changes
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  
  def object
    return nil if deleted?
    if model_name =~ /^([A-Z][a-z]{1,15})+$/
      @object ||= eval(model_name).find(instance_id) rescue nil
    end
  end
  
  def object_description
    return nil unless object
    if object.respond_to?(:name)
      object.name
    elsif object.is_a? Contact
      object.person.name rescue '???'
    elsif object.is_a? Membership
      "#{object.person.name} in group #{object.group.name}" rescue '???'
    else
      object.id
    end
  end
  
  def object_excerpt
    return nil unless object
    case model_name
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
    action = 'view'
    id = instance_id
    case model_name
    when 'Event'
      controller = 'pictures'
      action = 'view_event'
    when 'Comment'
      controller = 'verses'
      id = object.verse.id
    when 'Family'
      controller = 'people'
      id = object.people.first.id
    when 'Membership'
      controller = 'groups'
      id = object.group.id rescue nil
    else
      controller = model_name.pluralize.downcase
  end
    "/#{controller}/#{action}/#{id}"
  end
  
  def object_image_url
    return nil if deleted?
    return nil unless object.respond_to? 'has_photo?' and object.has_photo?
    controller = model_name.pluralize.downcase
    action = 'photo'
    id = "#{instance_id}.tn.jpg"
    "/#{controller}/#{action}/#{id}"
  end
  
  def showable_change_keys
    return [] if deleted?
    changes.keys.select do |key|
      PEOPLE_ATTRIBUTES_SHOWABLE_ON_HOMEPAGE.include? key
    end.map do |key|
      key == 'tv_shows' ? 'TV Shows' : key.split('_').map { |w| w.capitalize }.join(' ')
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
      conditions = ["model_name in ('Message', 'Comment')"]
      if since
        since = Time.now - since.days if since.is_a? Fixnum
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
