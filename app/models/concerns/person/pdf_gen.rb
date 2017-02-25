module Concerns
  module Person
    module PdfGen
      def generate_directory_pdf(with_pictures = false)
        PrintableDirectory.new(self, pictures: with_pictures).render
      end

      def generate_directory_pdf_to_file(filename, with_pictures = false)
        File.open(filename, 'wb') { |f| f.write(generate_directory_pdf(with_pictures)) }
      end

      def generate_and_email_directory_pdf(with_pictures = false)
        filename = "#{Rails.root}/tmp/directory_for_user#{id}.pdf"
        generate_directory_pdf_to_file(filename, with_pictures)
        Notifier.printed_directory(self, File.open(filename)).deliver_now
      end
    end
  end
end
