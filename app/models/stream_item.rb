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

  after_save :expire_caches
  after_destroy :expire_caches

  # can't do this in a sweeper since there isn't a controller involved
  def expire_caches
    if %w(NewsItem Publication).include?(streamable_type)
      ActionController::Base.cache_store.delete_matched(%r{stream\?for=\d+&fragment=stream_items})
    elsif person
      ids = [person_id] + person.all_friend_and_groupy_ids
      ActionController::Base.cache_store.delete_matched(%r{stream\?for=(#{ids.join('|')})&fragment=stream_items})
    end
    if group_id
      ActionController::Base.cache_store.delete_matched(%r{groups/#{group_id}\?fragment=stream_items})
    end
  end

  def can_have_comments?
    %w(Verse Note Album).include?(streamable_type)
  end
end
