class GeneratedFile < ApplicationRecord
  MAX_WAIT_SECONDS = 1800 # 30 minutes

  belongs_to :person

  scope_by_site_id
  scope :stale, -> { where('created_at < ?', 1.day.ago) }

  has_attached_file :file, PAPERCLIP_FILE_OPTIONS
  do_not_validate_attachment_file_type :file
end
