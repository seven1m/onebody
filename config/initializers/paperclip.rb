PAPERCLIP_PHOTO_OPTIONS = {
  :path          => ":rails_root/public/system/:rails_env/:class/:attachment/:id/:style/:fingerprint.:extension",
  :url           => "/system/:rails_env/:class/:attachment/:id/:style/:fingerprint.:extension",
  :styles        => {
    :tn          => '32x32#',
    :small       => '75x75>',
    :medium      => '150x150>',
    :profile     => '300x500>',
    :large       => '400x400>',
    :original    => '800x800>'
  },
  :default_url   => "/images/missing_:style.png"
}

PAPERCLIP_PHOTO_MAX_SIZE = 5.megabytes
PAPERCLIP_PHOTO_CONTENT_TYPES = ['image/jpeg', 'image/jpg', 'image/pjpeg', 'image/png', 'image/x-png']

PAPERCLIP_FILE_OPTIONS = {
  :path          => ":rails_root/public/system/:rails_env/:class/:attachment/:id/:fingerprint.:extension",
  :url           => "/system/:rails_env/:class/:attachment/:id/:fingerprint.:extension"
}

PAPERCLIP_FILE_MAX_SIZE = 25.megabytes

# this patch is necessary due to filed bug:
# http://github.com/thoughtbot/paperclip/issues/issue/337
# TODO remove once bug is fixed in Paperclip
class ActionDispatch::Http::UploadedFile
  include Paperclip::Upfile
end
