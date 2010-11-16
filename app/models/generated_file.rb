class GeneratedFile < ActiveRecord::Base
  MAX_WAIT_SECONDS = 1800 # 30 minutes
  belongs_to :job
  belongs_to :person
  scope_by_site_id
  has_attached_file :file, PAPERCLIP_FILE_OPTIONS
end
