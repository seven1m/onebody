class StreamItem < ActiveRecord::Base
  belongs_to :person
  belongs_to :site
  belongs_to :group
  belongs_to :streamable, :polymorphic => true
  
  serialize :context
  
  scope_by_site_id
  
  def title
    read_attribute(:title) || case streamable_type
      when 'Note'
        'Note'
      else
        nil
    end
  end
  
  before_save :ensure_context_is_hash
  
  def ensure_context_is_hash
    self.context = {} if not context.is_a?(Hash)
  end
end
