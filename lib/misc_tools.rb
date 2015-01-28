class Hash
  # for each key specified, sets its value to nil if it is blank
  def cleanse(*keys)
    keys.each do |key|
      self[key] = nil if self.has_key?(key) and self[key].blank?
    end
  end

  def reject_blanks ; reject  { |k, v| v.to_s.empty? }; end
  def reject_blanks!; reject! { |k, v| v.to_s.empty? }; end

  def to_date
    Date.new(self[:year].to_i, self[:month].to_i, self[:day].to_i) rescue nil
  end

  def +(hash)
    self.merge hash
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

  def digits_only
    d = scan(/\d/)
    d.join if d.any?
  end
end

class Array
  def rand_count(count)
    selected = []
    cage = self.clone
    count.times do
      selected << (picked = cage.rand)
      cage -= [picked]
    end
    return selected.compact
  end
end
