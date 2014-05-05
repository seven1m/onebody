class Person

  module Export

    EXPORT_COLS = {
      person: %w(
        family_id
        sequence
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
        activities
        interests
        music
        tv_shows
        movies
        books
        quotes
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
        can_sign_in
        visible_to_everyone
        visible_on_printed_directory
        full_access
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
    } unless defined?(EXPORT_COLS)

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def to_csv
        CSV.generate do |csv|
          csv << EXPORT_COLS[:person] + EXPORT_COLS[:family].map { |c| "family_#{c}" }
          total = Person.undeleted.count
          (1..(total/100+1)).each do |page|
            Person.undeleted.includes(:family).paginate(per_page: 100, page: page).each do |person|
              next unless person.family
              csv << EXPORT_COLS[:person].map { |c| person.send(c) } + \
                     EXPORT_COLS[:family].map { |c| person.family.send(c) }
            end
          end
        end
      end

      def create_to_csv_job
        Job.add("GeneratedFile.create!(:job_id => JOB_ID, :person_id => #{Person.logged_in.id}, :file => FakeFile.new(Person.to_csv, 'people.csv'))")
      end

      def to_xml
        builder = Builder::XmlMarkup.new
        builder.families do |families|
          total = Family.undeleted.count
          (1..(total/100+1)).each do |page|
            Family.undeleted.includes(:people).paginate(per_page: 100, page: page).each do |family|
              families.family do |fam|
                EXPORT_COLS[:family].each do |col|
                  fam.tag!(col, family.send(col))
                end
                fam.people do |people|
                  family.people.sort_by(&:sequence).each do |person|
                    people.person do |p|
                      inherited_attributes = Person.class_eval('@inherited_attributes')
                      EXPORT_COLS[:person].each do |col|
                        p.tag!(col, person.attributes[col])
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end

      def create_to_xml_job
        Job.add("GeneratedFile.create!(:job_id => JOB_ID, :person_id => #{Person.logged_in.id}, :file => FakeFile.new(Person.to_xml, 'people.xml'))")
      end
    end

  end
end
