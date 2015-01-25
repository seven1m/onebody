module Concerns
  module Person
    module PdfGen
      def generate_directory_pdf(with_pictures=false)
        pdf = PDF::Writer.new
        pdf.margins_pt 70, 20, 20, 20
        pdf.open_object do |heading|
          pdf.save_state
          pdf.stroke_color! Color::RGB::Black
          pdf.stroke_style! PDF::Writer::StrokeStyle::DEFAULT

          size = 24

          x = pdf.absolute_left_margin
          y = pdf.absolute_top_margin + 30
          pdf.add_text x, y, "#{Setting.get(:name, :community)} #{I18n.t('nav.directory')}\n\n", size

          x = pdf.absolute_left_margin
          w = pdf.absolute_right_margin
          #y -= (pdf.font_height(size) * 1.01)
          y -= 10
          pdf.line(x, y, w, y).stroke

          pdf.restore_state
          pdf.close_object
          pdf.add_object(heading, :all_following_pages)
        end

        s = 24
        w = pdf.text_width(Setting.get(:name, :community), s)
        x = pdf.margin_x_middle - w/2 # centered
        y =  pdf.absolute_top_margin - 150
        pdf.add_text x, y, Setting.get(:name, :community), s
        s = 20
        w = pdf.text_width('Directory', s)
        x = pdf.margin_x_middle - w/2 # centered
        y =  pdf.absolute_top_margin - 200
        pdf.add_text x, y, I18n.t('nav.directory'), s

        t = I18n.t('printable_directories.created_for', { name: self.name, date: (Date.today.strftime '%B %e, %Y') } )
        s = 14
        w = pdf.text_width(t, s)
        x = pdf.margin_x_middle - w/2 # centered
        y = pdf.margin_y_middle - pdf.margin_height/3 # below center
        pdf.add_text x, y, t, s

        pdf.start_new_page
        pdf.start_columns

        alpha = nil

        families = Family.has_printable_people.includes(:people) \
          .order('families.last_name, families.name, people.position').references(:people)
        families.each do |family|
          if family.mapable? or family.home_phone.to_i > 0
            pdf.move_pointer 120 if pdf.y < 120
            if family.last_name[0..0] != alpha
              if with_pictures and family.photo.exists?
                pdf.move_pointer 450 if pdf.y < 450
              else
                pdf.move_pointer 150 if pdf.y < 150
              end
              alpha = family.last_name[0..0]
              pdf.text alpha + "\n", font_size: 25
              pdf.line(
                pdf.absolute_left_margin,
                pdf.y - 5,
                pdf.absolute_left_margin + pdf.column_width - 25,
                pdf.y - 5
              ).stroke
              pdf.move_pointer 10
            end
            if with_pictures and family.photo.exists?
              if pdf.y < 300
                pdf.move_pointer 300
              else
                pdf.move_pointer 20
              end
              pdf.text family.name + "\n", font_size: 18
              pdf.move_pointer 10
              image_file = File.read(family.photo.path(:large), encoding: 'binary', mode: 'rb')
              image = MiniMagick::Image.new(family.photo.path(:large))
              width = (150.0 / image[:height] * image[:width]).to_i
              pdf.add_image image_file, pdf.absolute_left_margin, pdf.y-150, width, 150
              pdf.move_pointer 160
            else
              pdf.text family.name + "\n", font_size: 18
            end
            if family.people.detect { |p| p.share_address_with(self) } and [family.address1, family.city, family.state].all?(&:present?)
              pdf.text family.address1 + "\n", font_size: 14
              pdf.text family.address2 + "\n" if family.address2.present?
              pdf.text family.city + ', ' + family.state + '  ' + family.zip.to_s + "\n"
            end
            pdf.text ApplicationHelper.format_phone(family.home_phone), font_size: 14 if family.home_phone.to_i > 0
            family.people.where(deleted: false).each do |person|
              name = person.last_name == family.last_name ? person.first_name : person.name
              pdf.text "\n", font_size: 11
              pdf.add_text_wrap pdf.absolute_left_margin, pdf.y, 400, name, 11
              details = ''
              if person.show_attribute_to?(:mobile_phone, self)
                details += '   ' + ApplicationHelper.format_phone(person.mobile_phone, :mobile)
              end
              if person.show_attribute_to?(:email, self)
                details += '   ' + person.email
              end
              pdf.add_text_wrap pdf.absolute_left_margin + pdf.text_width(name, 11), pdf.y, 200, details, 9
            end
            pdf.text "\n"
          end
        end

        pdf
      end

      def generate_directory_pdf_to_file(filename, with_pictures=false)
        File.open(filename, 'wb') { |f| f.write(generate_directory_pdf(with_pictures)) }
      end

      def generate_and_email_directory_pdf(with_pictures=false)
        filename = "#{Rails.root}/tmp/directory_for_user#{id}.pdf"
        generate_directory_pdf_to_file(filename, with_pictures)
        Notifier.printed_directory(self, File.open(filename)).deliver_now
      end
    end
  end
end
