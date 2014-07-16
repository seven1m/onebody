module Checkin::CheckinsHelper

  def checkin_person_icon(person)
    if person.child
      case person.gender
      when 'Female'
        icon('fa fa-child text-pink')
      when 'Male'
        icon('fa fa-child text-blue')
      else
        icon('fa fa-user')
      end
    else
      case person.gender
      when 'Female'
        icon('fa fa-female text-pink')
      when 'Male'
        icon('fa fa-male text-blue')
      else
        icon('fa fa-user')
      end
    end
  end

  def checkin_labels_as_json
    CheckinLabel.all.each_with_object({}) do |label, hash|
      hash[label.id] = label.xml
    end
  end

end
