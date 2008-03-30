require 'active_record'
require 'net/http'
require 'mini_magick'

module Foo
  module Acts #:nodoc:
    module Photo #:nodoc:

      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_photo(storage_path, sizes)
          sizes.each do |name, dimensions|
            class_eval <<-END
              def photo_#{name.to_s}_path
                File.join('#{storage_path}', id.to_s + ".#{name.to_s}.jpg")
              end
            END
          end
          class_eval <<-END
            PHOTO_SIZES = #{sizes.inspect}
            
            def has_photo?
              @has_photo ||= FileTest.exists?(photo_path)
            end
            
            def photo_path
              File.join('#{storage_path}', id.to_s + '.jpg')
            end
            
            def photo_path_from_id(id)
              if id.to_s.count('.') == 2
                send('photo_' + id.to_s.split('.')[1] + '_path')
              else
                photo_path
              end
            end
            
            def photo=(photo)
              File.delete photo_path if FileTest.exists? photo_path
              PHOTO_SIZES.each do |name, dimensions|
                path = send('photo_' + name.to_s + '_path')
                File.delete path if FileTest.exists? path
              end
              if photo
                if defined? photo.read
                  photo = photo.read
                elsif photo.is_a?(String) and photo =~ /^http:\\/\\// #/
                  photo = Net::HTTP.get(URI.parse(photo))
                else # not a photo I know how to handle
                  return false
                end
                begin
                  img = MiniMagick::Image.from_blob(photo)
                rescue # error with photo -- maybe zero length?
                  return false
                end
                if img['format'] == 'JPEG'
                  img.write photo_path
                  File.chmod(0644, photo_path)
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
              return true
            end
            
            def rotate_photo(degrees)
              PHOTO_SIZES.each do |name, dimensions|
                path = send('photo_' + name.to_s + '_path')
                img = MiniMagick::Image.from_blob(File.read(path))
                img.rotate(degrees).write(path)
                File.chmod(0644, path)
              end
            end
            
            def destroy
              photo = nil
              super
            end
          END
        end
      end

    end
  end
end

# reopen ActiveRecord and include all the above to make
# them available to all our models if they want it

ActiveRecord::Base.class_eval do
  include Foo::Acts::Photo
end

# application controller

class ActionController::Base
  def send_photo(object)
    if object.has_photo?
      if params[:id] =~ /^\d+\.[a-z]+\.jpg$/ and request.env["HTTP_ACCEPT"].split(/,|;/).include? 'text/html'
        render :file => File.join(RAILS_ROOT, 'app/views/picture.html.erb'), :layout => true
      else
        path = object.photo_path_from_id(params[:id])
        updated_time = File.stat(path).mtime
        browser_time = Time.rfc2822(request.env["HTTP_IF_MODIFIED_SINCE"]) rescue nil
        if browser_time.nil? or updated_time > browser_time
          response.headers['Last-Modified'] = updated_time.httpdate
          send_file path, :type => 'image/jpeg', :disposition => 'inline'
        else
          render :text => 'photo not modified', :status => 304
        end
      end
    else
      render :text => 'photo unavailable', :status => 404
    end
  end
end
