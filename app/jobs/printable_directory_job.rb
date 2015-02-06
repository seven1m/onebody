class PrintableDirectoryJob < ActiveJob::Base
  queue_as :directory

  def perform(person, with_pictures = false)
    person.generate_and_email_directory_pdf(with_pictures)
  end
end
