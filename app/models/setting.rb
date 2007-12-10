class Setting < ActiveRecord::Base
  serialize :value
  
  def value
    v = read_attribute(:value)
    format == 'boolean' ? ![0, '0'].include?(v) : v
  end
  
  def value?; value; end
end
