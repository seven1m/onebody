class MoveAttachmentsToFilesystem < ActiveRecord::Migration
  
  class PseudoFile < StringIO
    EXTENSIONS = Attachment::CONTENT_TYPES.invert
    attr_accessor :original_filename
    def initialize(data, content_type)
      super(data)
      ext = EXTENSIONS[content_type] || 'bin'
      puts content_type if ext == 'bin'
      self.original_filename = "something.#{ext}"
    end
  end
  
  def self.up
    unless File.exists? DB_ATTACHMENTS_PATH
      FileUtils.mkdir DB_ATTACHMENTS_PATH
    end
    Site.each do |site|
      Attachment.find(:all).each do |attachment|
        data = attachment.read_attribute(:file)
        attachment.file = PseudoFile.new(data, attachment.content_type)
      end
    end
    remove_column :attachments, :file
  end

  def self.down
    add_column :attachments, :file, :binary, :limit => 10485760
    Site.each do |site|
      Attachment.find(:all).each do |attachment|
        data = File.read(attachment.file_path)
        attachment.write_attribute :file, data
        attachment.save
      end
    end
    puts 'You must manually remove the files from db/attachments/*'
  end
end
