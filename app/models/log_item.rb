class LogItem < ActiveRecord::Base
  belongs_to :person
  
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
      truncate(object.body)
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
end
