class StreamItem < ActiveRecord::Base
  belongs_to :person
  belongs_to :site
  belongs_to :group
  belongs_to :streamable, polymorphic: true

  serialize :context, Hash

  scope_by_site_id

  def can_have_comments?
    %w(Verse Note Album).include?(streamable_type)
  end
end
