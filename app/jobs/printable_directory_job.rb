class PrintableDirectoryJob < ActiveJob::Base
  queue_as :directory

  def perform(site, person_id, file_id, with_pictures = false)
    ActiveRecord::Base.connection_pool.with_connection do
      Site.with_current(site) do
        person = Person.find(person_id)
        file = person.generated_files.find(file_id)
        data = PrintableDirectory.new(person, pictures: with_pictures).render
        file.file = StringIO.new(data)
        file.save
      end
    end
  end
end
