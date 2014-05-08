class Person

  cattr_accessor :import_in_progress

  MAX_RECORDS_TO_IMPORT = 500 unless defined?(MAX_RECORDS_TO_IMPORT)

  COLUMN_ALIASES = {
    'First Name'             => 'first_name',
    'Last Name'              => 'last_name',
    'Household Name Format'  => 'family_name',
    'Gender'                 => 'gender',
    'DOB'                    => 'birthday',
    'Address1'               => 'family_address1',
    'Address 1'              => 'family_address1',
    'Address2'               => 'family_address2',
    'Address 2'              => 'family_address2',
    'City'                   => 'family_city',
    'State Province'         => 'family_state',
    'Postal Code'            => 'family_zip',
    'Home Phone'             => 'family_home_phone',
    'Work Phone'             => 'work_phone',
    'Cell Phone'             => 'mobile_phone',
    'Individual Email'       => 'email',
    'Household Email'        => 'family_email'
  } unless defined?(COLUMN_ALIASES)

  module Import
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def importable_column_names
        # FIXME
        (Person.attr_accessible.keys + Family.attr_accessible.keys.map { |k| "family_#{k}" }).uniq
      end

      def translate_column_name(col)
        importable_column_names.include?(col) ? col : COLUMN_ALIASES[col]
      end

      def queue_import_from_csv_file(file, match_by_name=true, merge_attributes={})
        Person.import_in_progress = true
        data = CSV.parse(file)
        attributes = data.shift.map { |a| translate_column_name(a) }
        the_changes = data[0...MAX_RECORDS_TO_IMPORT].map do |row|
          person, family = get_changes_for_import(attributes, row, match_by_name)
          person.attributes = merge_attributes
          if person.changed? or family.changed?
            changes = person.changes.clone
            family.changes.each { |k, v| changes['family_' + k] = v }
            [person, changes]
          else
            nil
          end
        end.compact
        Person.import_in_progress = false
        the_changes
      end

      def get_changes_for_import(attributes, row, match_by_name=true)
        row_as_hash = {}
        row.each_with_index do |col, index|
          if a = attributes[index]
            row_as_hash[a] = col
          end
        end
        person_hash, family_hash = split_change_hash(row_as_hash)
        if record = tiered_find(person_hash, match_by_name)
          record.attributes = person_hash
          if record.family
            record.family.attributes = family_hash
            [record, record.family]
          else
            [record, Family.new(family_hash)]
          end
        else
          [new(person_hash), Family.new(family_hash)]
        end
      end

      def tiered_find(attributes, match_by_name=true)
        a = attributes.clone.reject_blanks
        a['id']        &&
          where(id: a["id"]).first               ||
        a['legacy_id'] &&
          where(legacy_id: a["legacy_id"]).first ||
        match_by_name  && a['first_name'] && a['last_name'] && a['birthday'] &&
          where(first_name: a["first_name"], last_name: a["last_name"], birthday: Date.parse(a["birthday"])).first ||
        match_by_name  && a['first_name'] && a['last_name'] &&
          where(first_name: a["first_name"], last_name: a["last_name"]).first
      end

      def import_data(params)
        Person.import_in_progress = true
        completed = []
        errored = []
        params[:new].to_a.each do |key, vals|
          Person.transaction do
            begin
              person_vals, family_vals = split_change_hash(vals)
              name = "#{person_vals['first_name']} #{person_vals['last_name']}"
              last_name = person_vals['last_name']
              if family_vals['id']
                family = Family.where(id: family_vals["id"]).first
              elsif family_vals['legacy_id']
                family = Family.where(legacy_id: family_vals["legacy_id"]).first
              end
              family ||= Family.create!({'name' => name, 'last_name' => last_name})
              family.update_attributes!(family_vals)
              person = Person.create!(person_vals.merge('family_id' => family.id))
            rescue => e
              if person_vals
                errored << {first_name: person_vals['first_name'], last_name: person_vals['last_name'], status: 'Error creating record.', message: e.message}
              else
                errored << {status: 'Error creating record.', message: e.message}
              end
              raise ActiveRecord::Rollback
            else
              completed << {first_name: person_vals['first_name'], last_name: person_vals['last_name'], status: 'Record created.'}
            end
          end
        end
        params[:changes].to_a.each do |id, vals|
          Person.transaction do
            begin
              vals.cleanse('birthday', 'anniversary')
              person_vals, family_vals = split_change_hash(vals)
              person = Person.find(id)
              person.update_attributes!(person_vals)
              person.family.update_attributes!(family_vals)
            rescue => e
              if person
                errored << {first_name: person.first_name, last_name: person.last_name, status: I18n.t('import.error_updating'), message: e.message}
              else
                errored << {status: I18n.t('import.error_updating'), message: e.message}
              end
              raise ActiveRecord::Rollback
            else
              completed << {first_name: person.first_name, last_name: person.last_name, status: I18n.t('import.record_updated')}
            end
          end
        end
        Person.import_in_progress = false
        [completed, errored]
      end

      def split_change_hash(vals)
        person_vals = {}
        family_vals = {}
        vals.each do |key, val|
          if key =~ /^family_/
            family_vals[key.sub(/^family_/, '')] = val
          else
            person_vals[key] = val
          end
        end
        family_vals['legacy_id'] ||= person_vals['legacy_family_id']
        person_vals.reject! { |k, v| !Person.column_names.include?(k) or k =~ /^share_|_at$/ }
        family_vals.reject! { |k, v| !Family.column_names.include?(k) or k =~ /^share_|_at$/ }
        [person_vals, family_vals]
      end
    end
  end
end
