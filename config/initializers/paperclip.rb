PAPERCLIP_PHOTO_OPTIONS = {
  path: ":rails_root/public/system/:rails_env/:class/:attachment/:id/:style/:fingerprint.:extension",
  url:  "/system/:rails_env/:class/:attachment/:id/:style/:fingerprint.:extension",
  styles: {
    tn:       '70x70#',
    small:    '150x150>',
    medium:   '500x500>',
    large:    '800x800>',
    original: '1600x1600>'
  },
  default_url: "/images/missing_:style.png"
}

PAPERCLIP_PHOTO_MAX_SIZE = 10.megabytes
PAPERCLIP_PHOTO_CONTENT_TYPES = ['image/jpeg', 'image/jpg', 'image/pjpeg', 'image/png', 'image/x-png']

PAPERCLIP_FILE_OPTIONS = {
  path: ":rails_root/public/system/:rails_env/:class/:attachment/:id/:fingerprint.:extension",
  url:  "/system/:rails_env/:class/:attachment/:id/:fingerprint.:extension"
}

PAPERCLIP_FILE_MAX_SIZE = 75.megabytes
