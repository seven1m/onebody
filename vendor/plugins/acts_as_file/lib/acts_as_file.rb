require 'active_record'

module Foo
  module Acts #:nodoc:
    module FilePlugin #:nodoc:

      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_file(storage_path)
          class_eval <<-END
            CONTENT_TYPES = {
              'gif' => "image/gif",
              'jpg' => "image/jpeg",
              'png' => "image/png",
              'swf' => "application/x-shockwave-flash",
              'pdf' => "application/pdf",
              'doc' => "application/msword",
              'zip' => "application/zip",
              'mp3' => "audio/mpeg",
              'wma' => "audio/x-ms-wma",
              'wav' => "audio/x-wav",
              'css' => "text/css",
              'html' => "text/html",
              'js' => "text/javascript",
              'txt' => "text/plain",
              'xml' => "text/xml",
              'mpeg' => "video/mpeg",
              'mpg' => "video/mpeg",
              'mov' => "video/quicktime",
              'avi' => "video/x-msvideo",
              'asf' => "video/x-ms-asf",
              'wmv' => "video/x-ms-wmv"
            }
          
            def has_file?
              !file_path.nil?
            end
            
            def file_name
              return nil unless id
              directory = File.join(RAILS_ROOT, '#{storage_path}')
              matches = Dir.new(directory).grep(Regexp.new('^' + id.to_s + '.'))
              matches.any? ? matches.first : nil
            end
            
            def file_path
              file_name ? File.join(RAILS_ROOT, '#{storage_path}', file_name) : nil
            end
            
            def file_content_type
              file_name ? CONTENT_TYPES[file_name.split('.').last] : nil
            end
            
            def file=(file)
              raise 'Cannot save file before saving record.' unless id
              File.delete file_path if file_path
              if file
                if defined? file.read
                  filename = file.original_filename
                  file = file.read
                else # not a file I know how to handle
                  return false
                end
                output_path = File.join(RAILS_ROOT, '#{storage_path}', id.to_s + '.' + filename.split('.').last.downcase)
                File.open(output_path, 'w') do |f|
                  f.write(file)
                end
              end
              return true
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
  include Foo::Acts::FilePlugin
end
