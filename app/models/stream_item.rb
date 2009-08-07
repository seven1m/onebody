# == Schema Information
#
# Table name: stream_items
#
#  id              :integer       not null, primary key
#  site_id         :integer       
#  title           :string(500)   
#  body            :text          
#  context         :text          
#  person_id       :integer       
#  group_id        :integer       
#  streamable_id   :integer       
#  streamable_type :string(255)   
#  created_at      :datetime      
#  updated_at      :datetime      
#  wall_id         :integer       
#  shared          :boolean       
#

class StreamItem < ActiveRecord::Base
  belongs_to :person
  belongs_to :wall, :class_name => 'Person'
  belongs_to :site
  belongs_to :group
  belongs_to :streamable, :polymorphic => true
  
  serialize :context
  
  scope_by_site_id
  
  before_save :ensure_context_is_hash
  
  def ensure_context_is_hash
    self.context = {} if not context.is_a?(Hash)
  end
  
  def can_have_comments?
    %w(Verse Note Recipe Album).include?(streamable_type)
  end
end
