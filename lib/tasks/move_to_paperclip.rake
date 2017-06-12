namespace :onebody do
  desc 'Move existing pictures and files to new locations for OneBody 2.0.0.'
  task move_to_paperclip: :environment do
    require 'fileutils'
    paths = Dir[DB_PHOTO_PATH.join('**/*')].to_a + \
      Dir[DB_ATTACHMENTS_PATH.join('**/*')].to_a
    paths.each_with_index do |path, index|
      if path =~ %r{db/photos}
        _, collection, id, _, env, size = path.match(%r{db/photos/(.+)/(\d+)(\.(test|development))?\.(tn|small|medium|large|full)\.jpg}).to_a
        next if size != 'full'
        attribute = 'photo'
      else
        _, collection, id, _, env, extension = path.match(%r{db/(.+)/(\d+)(\.(test|development))?\.(.+)$}).to_a
        attribute = 'file'
      end
      next if collection.nil?
      next if collection == 'recipes'
      klass = Object.const_get(collection.singularize.capitalize)
      env = 'production' if env.nil?
      next if Rails.env.to_s != env
      begin
        object = klass.unscoped { klass.find(id) }
      rescue ActiveRecord::RecordNotFound
        puts "Warning: #{klass.name} with id #{id} was not found."
        puts "       This file/photo was not copied: #{path}"
      else
        object.send("#{attribute}=", File.open(path))
        #klass.skip_callback :save do
          #object.save(:validate => false)
        #end
        #object.save_attached_files
        # manually update db so as to not trigger any callbacks
        Person.connection.execute("UPDATE #{collection} SET #{attribute}_updated_at='#{Time.now.utc}', #{attribute}_fingerprint='#{object.attributes[attribute + '_fingerprint']}', #{attribute}_file_size=#{object.attributes[attribute + '_file_size']}, #{attribute}_content_type='#{object.attributes[attribute + '_content_type']}', #{attribute}_file_name='#{object.attributes[attribute + '_file_name']}' WHERE id=#{object.id}")
        puts "Copied #{path} =>\n       #{object.send(attribute).path}"
      end
      puts "       #{index + 1}/#{paths.length} complete."
    end
    if paths.any?
      puts
      puts '============================================================================'
      puts 'Operation complete.'
      puts 'Please check that all photos and files are in place in public/system.'
      puts 'Then you can delete the db/photos and db/attachments dirs.'
      puts '============================================================================'
      puts
    end
  end
end
