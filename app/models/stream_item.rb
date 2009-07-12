class StreamItem < ActiveRecord::Base
  belongs_to :person
  belongs_to :site
  belongs_to :group
  belongs_to :streamable, :polymorphic => true
  
  serialize :context
  
  def title
    read_attribute(:title) || case streamable_type
      when 'Note'
        'Note'
      else
        nil
    end
  end
end
