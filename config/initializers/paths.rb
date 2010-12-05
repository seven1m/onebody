unless defined? DB_PHOTO_PATH
  DB_PHOTO_PATH        = Rails.root.join('db/photos')
  DB_PUBLICATIONS_PATH = Rails.root.join('db/publications')
  DB_ATTACHMENTS_PATH  = Rails.root.join('db/attachments')
end
