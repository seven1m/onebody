unless defined? DB_PHOTO_PATH
  DB_PHOTO_PATH        = File.join(RAILS_ROOT, 'db/photos')
  DB_PUBLICATIONS_PATH = File.join(RAILS_ROOT, 'db/publications')
  DB_ATTACHMENTS_PATH  = File.join(RAILS_ROOT, 'db/attachments')
  DB_TASK_FILES_PATH   = File.join(RAILS_ROOT, 'db/task_files')
end