class SyncItem < ActiveRecord::Base
  belongs_to :site

  scope_by_site_id

  scope :creates, -> { where(operation: 'create') }
  scope :updates, -> { where(operation: 'update') }
  scope :errors, -> { where(status: ['error', 'saved with error']) }

  serialize :error_messages

  belongs_to :sync
  belongs_to :syncable, polymorphic: true
end
