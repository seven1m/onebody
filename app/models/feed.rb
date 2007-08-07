class Feed < ActiveRecord::Base
  belongs_to :person
  belongs_to :group
  
  def fetch
    
  end
  
  class << self
    
  end
end
