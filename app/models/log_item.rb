class LogItem < ActiveRecord::Base
  def object
    if model_name =~ /^[A-Z][a-z]{1,15}$/
      @object ||= eval(model_name).find(instance_id) rescue nil
    end
  end
  
  def object_description
    return nil unless object
    if object.respond_to?(:name)
      object.name
    elsif object.is_a? Comment
      "Comment on #{object.verse.reference}"
    else  
      object.id
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
      else
        controller = model_name.pluralize.downcase
    end
    "/#{controller}/#{action}/#{id}"
  end
  
  serialize :changes
end
