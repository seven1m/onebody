module Concerns
  module Person
    module Batch
      def self.included(mod)
        mod.extend(ClassMethods)
      end

      def set_attributes_from_batch(attributes)
        attributes.each do |key, value|
          value = nil if value.respond_to?(:strip) && value.strip == '' # don't use .presence here!
          # avoid overwriting a newer email address
          if key == 'email' and email_changed?
            if value == email # email now matches (presumably, the external db has been updated to match the OneBody db)
              self.email_changed = false # clear the flag
            else
              next # don't overwrite the newer email address with an older one
            end
          elsif %w(family email_changed remote_hash relationships relationships_hash site_id).include?(key) # skip these
            next
          end
          send("#{key}=", value)
        end
      end

      def update_relationships_from_batch!(attributes)
        if attributes['relationships_hash'] != relationships_hash
          relationships.to_a.select do |relationship|
            !Setting.get(:system, :online_only_relationships).include?(relationship.name_or_other)
          end.each { |r| r.delete }
          attributes['relationships'].to_s.split(',').each do |relationship|
            if relationship =~ /(\d+)\[([^\]]+)\]/ and related = ::Person.where(legacy_id: $1).first
              relationships.create(
                related:    related,
                name:       'other',
                other_name: $2
              )
            end
          end
          update_relationships_hash!
        end
      end

      module ClassMethods
        MAX_TO_BATCH_AT_A_TIME = 50

        # used to update a batch of records at one time, for UpdateAgent API
        def update_batch(records, options={})
          raise "Too many records to batch at once (#{records.length})" if records.length > MAX_TO_BATCH_AT_A_TIME
          records.map do |record|
            person = find_or_build_person(record, options)
            person.set_attributes_from_batch(record)
            person.dont_mark_email_changed = true # set flag to indicate we're the api
            if person.save
              person.update_relationships_from_batch!(record)
              { status: 'saved', legacy_id: person.legacy_id, id: person.id, name: person.name }.tap do |s|
                if person.email_changed? # email_changed flag still set
                  s[:status] = 'saved with error'
                  s[:error] = "Newer email not overwritten: \"#{person.email}\""
                end
              end
            else
              { status: 'not saved', legacy_id: record['legacy_id'], id: person.id, name: person.name, error: person.errors.full_messages.join('; ') }
            end
          end
        end

        def find_or_build_person(record, options)
          person = where(legacy_id: record["legacy_id"]).first
          family_id = Family.connection.select_value("select id from families where legacy_id = #{record['legacy_family_id'].to_i} and site_id = #{Site.current.id}")
          if person.nil? and options['claim_families_by_barcode_if_no_legacy_id'] and family_id
            # family should have already been claimed by barcode -- we're just going to try to match up people by name
            if person = where(family_id: family_id, legacy_id: nil, first_name: record['first_name'], last_name: record['last_name']).first
              # person already exists but is deleted, so undelete them
              person.deleted = false
            end
          end
          person ||= new # last resort, create a new record
          person.family_id = family_id
          person
        end
      end
    end
  end
end
