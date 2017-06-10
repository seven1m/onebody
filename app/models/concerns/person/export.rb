module Concerns
  module Person
    module Export
      unless defined?(EXPORT_COLS)
        EXPORT_COLS = {
          person: %w(
            family_id
            position
            gender
            first_name
            last_name
            mobile_phone
            work_phone
            fax
            birthday
            email
            website
            classes
            shepherd
            mail_group
            about
            testimony
            share_mobile_phone
            share_work_phone
            share_fax
            share_email
            share_birthday
            share_address
            share_anniversary
            share_home_phone
            business_category
            business_name
            business_description
            business_address
            business_phone
            business_email
            business_website
            legacy_id
            suffix
            anniversary
            updated_at
            alternate_email
            account_frozen
            messages_enabled
            visible
            parental_consent
            friends_enabled
            member
            staff
            elder
            deacon
            status
            legacy_family_id
            share_activity
            child
            custom_type
            description
          ),
          family: %w(
            name
            last_name
            address1
            address2
            city
            state
            zip
            home_phone
            legacy_id
            updated_at
            visible
          )
        }.freeze
      end

      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def to_csv
          CSV.generate do |csv|
            custom_fields = CustomField.all
            csv << EXPORT_COLS[:person] + \
              EXPORT_COLS[:family].map { |c| "family_#{c}" } + \
              custom_fields.map(&:slug)
            ::Person.undeleted.includes(:family, :custom_field_values).find_each do |person|
              next unless person.family
              csv << EXPORT_COLS[:person].map { |c| person.send(c) } + \
                EXPORT_COLS[:family].map { |c| person.family.send(c) } + \
                custom_fields.map { |f| person.fields[f.id] }
            end
          end
        end

        def to_xml
          custom_fields = CustomField.all
          builder = Builder::XmlMarkup.new
          builder.families do |families|
            Family.undeleted.includes(people: :custom_field_values).find_each do |family|
              families.family do |fam|
                EXPORT_COLS[:family].each do |col|
                  fam.tag!(col, family.send(col))
                end
                fam.people do |people|
                  family.people.sort_by(&:position).each do |person|
                    people.person do |p|
                      EXPORT_COLS[:person].each do |col|
                        p.tag!(col, person.attributes[col])
                      end
                      custom_fields.each do |field|
                        p.tag!(field.slug, person.fields[field.id])
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
