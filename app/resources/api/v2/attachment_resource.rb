module Api
  module V2
    class AttachmentResource < OneBodyResource
      attributes :name, :content_type, :file_file_name, :file_content_type,
                 :file_fingerprint, :file_file_size, :file_updated_at

      has_one :message
      # has_one :page  # TODO implement resource and spec for pages
    end
  end
end