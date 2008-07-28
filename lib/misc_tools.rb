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
    d = scan(/\d/).join('')
    d.any? ? d : nil
  end
end

class Array
  def group_by_model_name(options={})
    except = options.delete(:except) || []
    only = options.delete(:only)
    grouped = []
    last_model_name = nil
    group = nil
    each do |item|
      if item.model_name != last_model_name or
        (except.include? item.model_name) or
        (only and not only.include? item.model_name)
        #or item.model_name != 'Picture'
        grouped << group if group
        group = []
      end
      group << item
      last_model_name = item.model_name
    end
    grouped << group if group
    return grouped
  end
  
  def with_indexes
    returning([]) do |with|
      self.each_with_index do |item, index|
        with << [item, index]
      end
    end
  end
end

def random_chars(length)
  (1..length).collect { (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }.join
end
