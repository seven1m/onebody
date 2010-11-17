class StorePhotoDetailsInStreamItems < ActiveRecord::Migration
  def self.up
    Site.each do
      StreamItem.where(:streamable_type => 'Album').each do |stream_item|
        if stream_item.context['picture_ids']
          new_picture_ids = []
          Array(stream_item.context['picture_ids']).each do |id|
            if id.is_a?(Array)
              new_picture_ids << id
            else
              picture = Picture.find(id)
              if picture.photo.exists?
                new_picture_ids << [id, picture.photo.fingerprint, picture.photo_extension]
              end
            end
          end
          stream_item.context['picture_ids'] = new_picture_ids
          stream_item.save!
        end
      end
    end
  end

  def self.down
    Site.each do
      StreamItem.where(:streamable_type => 'Album').each do |stream_item|
        if stream_item.context['picture_ids']
          old_picture_ids = []
          Array(stream_item.context['picture_ids']).each do |id|
            if id.is_a?(Array)
              old_picture_ids << id.first
            else
              old_picture_ids << id
            end
          end
          stream_item.context['picture_ids'] = old_picture_ids
          stream_item.save!
        end
      end
    end
  end
end
