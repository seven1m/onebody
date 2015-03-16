class PrintableDirectoryJob < ActiveJob::Base
  queue_as :directory

  def perform(site, person_id, with_pictures = false)
    ActiveRecord::Base.connection_pool.with_connection do
      Site.with_current(site) do
        Person.find(person_id).generate_and_email_directory_pdf(with_pictures)
      end
    end
  end
end
