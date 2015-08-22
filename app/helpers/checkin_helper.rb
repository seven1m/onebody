module CheckinHelper
  def checkin_labels_as_json
    CheckinLabel.all.each_with_object({}) do |label, hash|
      hash[label.id] = label.xml
    end
  end
end
