class LogItem < ActiveRecord::Base
  belongs_to :person
  belongs_to :reviewed_by, :class_name => 'Person', :foreign_key => 'reviewed_by'
  
  def object
    if model_name =~ /^[A-Z][a-z]{1,15}$/
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
    return nil unless object.respond_to? 'has_photo?' and object.has_photo?
    controller = model_name.pluralize.downcase
    action = 'photo'
    id = "#{instance_id}.tn.jpg"
    "/#{controller}/#{action}/#{id}"
  end
  
  serialize :changes
  
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
        since = Date.today - since if since.is_a? Fixnum
        conditions.add_condition ["created_at > ?", since]
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
