# == Schema Information
# Schema version: 20080709134559
#
# Table name: taggings
#
#  id            :integer       not null, primary key
#  tag_id        :integer       
#  taggable_id   :integer       
#  taggable_type :string(255)   
#  created_at    :datetime      
#

class Tagging < ActiveRecord::Base
  belongs_to :tag
  belongs_to :taggable, :polymorphic => true
  
  belongs_to :verse,  :foreign_key => 'taggable_id'
  belongs_to :recipe, :foreign_key => 'taggable_id'
  
  def after_destroy
    if Tag.destroy_unused
      if tag.taggings.count.zero?
        tag.destroy
      end
    end
  end
end
