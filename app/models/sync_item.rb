class SyncItem < ActiveRecord::Base
  belongs_to :site
  scope_by_site_id

  serialize :error_messages

  belongs_to :sync
  belongs_to :syncable, :polymorphic => true
end
