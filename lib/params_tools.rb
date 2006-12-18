class Hash
  # for each key specified, sets its value to nil if it is blank
  def cleanse(*keys)
    keys.each do |key|
      self[key] = nil if self[key].blank?
    end
  end
  
  def to_date
    Date.new(self[:year].to_i, self[:month].to_i, self[:day].to_i) rescue nil
  end
end

class Nil
  def to_date
    nil
  end
end

class String
  def to_date
    Date.parse(self) rescue nil
  end
end