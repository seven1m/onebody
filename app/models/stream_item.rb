class StreamItem < ActiveRecord::Base
  belongs_to :person
  belongs_to :site
  belongs_to :group
  belongs_to :streamable, polymorphic: true

  serialize :context

  scope_by_site_id

  before_save :ensure_context_is_hash

  def ensure_context_is_hash
    self.context = {} if not context.is_a?(Hash)
  end
  def can_have_comments?
    %w(Verse Note Album).include?(streamable_type)
  end
end
