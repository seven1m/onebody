class UpdatePhotoSizes < ActiveRecord::Migration
  def up
    Site.each do
      %w(Person Family Group Picture).each do |model|
        Kernel.const_get(model).where('photo_file_name is not null').find_each do |obj|
          begin
            obj.photo.reprocess!
          rescue
            msg = "Could not reprocess #{model} #{obj.id} photo! File may be missing."
            Rails.logger.error(msg)
            puts msg
          end
        end
      end
    end
  end

  def down
  end
end
