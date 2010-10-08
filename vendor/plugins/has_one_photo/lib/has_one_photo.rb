require 'active_record'
require 'net/http'
begin
  require 'mini_magick'
rescue LoadError
  puts 'mini_magick gem not installed'
end

module Seven1m
  module ActsAsPhoto

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def has_one_photo(options)
        options.symbolize_keys!
        # storage_path, sizes
        photo_env = Rails.env == 'production' ? '' : ('.' + Rails.env)
        options[:sizes].each do |name, dimensions|
          class_eval <<-END
            def photo_#{name.to_s}_path
              File.join('#{options[:path]}', id.to_s + "#{photo_env}.#{name.to_s}.jpg")
            end
          END
        end
        class_eval <<-END
          PHOTO_SIZES = #{options[:sizes].inspect}
          
          def has_photo?
            @has_photo ||= FileTest.exists?(photo_path)
          end
          
          def photo_path
            File.join('#{options[:path]}', id.to_s + '#{photo_env}.full.jpg')
          end
          
          def photo_path_from_params(params)
            if params[:id].to_s.count('.') == 2
              size = params[:id].to_s.split('.')[1]
            else
              size = params[:size]
            end
            if size.to_s.any? and self.respond_to?(m = 'photo_' + size + '_path')
              send(m)
            else
              photo_full_path
            end
          end
          
          def photo=(photo)
            PHOTO_SIZES.each do |name, dimensions|
              path = send('photo_' + name.to_s + '_path')
              File.delete path if FileTest.exists? path
            end
            if photo
              if photo.is_a?(String) and photo =~ /^http:\\/\\//
                photo = Net::HTTP.get(URI.parse(photo))
              else
                begin
                  photo = photo.read
                rescue
                  return false
                end
              end
              begin
                img = MiniMagick::Image.from_blob(photo)
              rescue # error with photo -- maybe zero length?
                return false
              end
              if img['format'] == 'JPEG'
                PHOTO_SIZES.each do |name, dimensions|
                  sized_img = MiniMagick::Image.from_blob(img.to_blob)
                  sized_img.thumbnail dimensions
                  sized_img.write send('photo_' + name.to_s + '_path')
                  File.chmod(0644, send('photo_' + name.to_s + '_path'))
                end
              else
                return false
              end
            end
            self.updated_at = Time.now
            save
            return true
          end
          
          def rotate_photo(degrees)
            PHOTO_SIZES.each do |name, dimensions|
              path = send('photo_' + name.to_s + '_path')
              img = MiniMagick::Image.from_blob(File.read(path))
              img.rotate(degrees)
              img.write(path)
              File.chmod(0644, path)
            end
            self.updated_at = Time.now
            save
          end
          
          def destroy
            self.photo = nil
            super
          end
        END
      end
    end

  end
end

ActiveRecord::Base.class_eval do
  include Seven1m::ActsAsPhoto
end

# application controller

class ActionController::Base
  def send_photo(object)
    if object.has_photo?
      path = object.photo_path_from_params(params)
      updated_time = File.stat(path).mtime
      if stale?(:last_modified => updated_time, :etag => object)
        expires_in 1.day
        send_file path, :type => 'image/jpeg', :disposition => 'inline'
      end
    else
      render :text => 'photo unavailable', :status => 404
    end
  end
end
