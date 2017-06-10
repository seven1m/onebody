class Tagging < ActiveRecord::Base
  belongs_to :tag
  belongs_to :taggable, polymorphic: true

  belongs_to :verse, foreign_key: 'taggable_id'

  after_destroy :destroy_tag_if_unused

  private

  def destroy_tag_if_unused
    if Tag.destroy_unused
      tag.destroy if tag.taggings.count.zero?
    end
  end
end
