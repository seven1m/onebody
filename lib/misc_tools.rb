class Hash
  # for each key specified, sets its value to nil if it is blank
  def cleanse(*keys)
    keys.each do |key|
      self[key] = nil if self.has_key?(key) and self[key].blank?
    end
  end

  def reject_blanks ; reject  { |k, v| v.to_s.empty? }; end
  def reject_blanks!; reject! { |k, v| v.to_s.empty? }; end

  def +(hash)
    self.merge hash
  end
end

class String
  def digits_only
    d = scan(/\d/)
    d.join if d.any?
  end
end
