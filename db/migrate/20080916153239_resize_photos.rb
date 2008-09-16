class ResizePhotos < ActiveRecord::Migration
  def self.up
    require 'mini_magick'
    %w(families groups people pictures recipes).each do |kind|
      Dir["#{DB_PHOTO_PATH}/#{kind}/*.jpg"].each do |pic|
        next if pic =~ /large|medium|small|tn|full/
        img = MiniMagick::Image.from_file(pic)
        img.thumbnail(PHOTO_SIZES[:full])
        new_path = pic.sub(/\.jpg$/, '.full.jpg')
        img.write(new_path)
        File.chmod(0644, new_path)
        File.delete(pic)
      end
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
