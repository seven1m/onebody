require_relative '../rails_helper'

describe ImportExecution do
  let(:import) do
    FactoryGirl.create(
      :import,
      status: 'active',
      match_strategy: 'by_id_only',
      mappings: {
        'id'        => 'id',
        'legacy_id' => 'legacy_id',
        'first'     => 'first_name',
        'last'      => 'last_name',
        'fam_id'    => 'family_id',
        'fam_name'  => 'family_name',
        'fam_lname' => 'family_last_name',
        'fam_lid'   => 'family_legacy_id',
        'phone'     => 'family_home_phone',
        'address'   => 'family_address1',
        'city'      => 'family_city',
        'state'     => 'family_state',
        'zip'       => 'family_zip',
        'email'     => 'email',
        'rel'       => 'relationships',
        'birthday'  => 'birthday'
      }
    )
  end

  subject { ImportExecution.new(import) }

  def create_row(attrs, status: :previewed)
    FactoryGirl.create(
      :import_row,
      import: import,
      status: status,
      import_attributes_attributes: attrs.each_with_index.map do |(name, value), index|
        { import: import, name: name.to_s, value: value, sequence: index }
      end
    )
  end

  describe '#execute' do
    it 'updates the import status' do
      expect { subject.execute }.to change(import, :status).to('complete')
    end

    it 'sets the completed_at time' do
      subject.execute
      expect(import.completed_at).to be
    end

    context 'given custom attributes' do
      let(:string_field) { FactoryGirl.create(:custom_field, name: 'foo',    format: 'string') }
      let(:date_field)   { FactoryGirl.create(:custom_field, name: 'date',   format: 'date') }
      let(:bool_field)   { FactoryGirl.create(:custom_field, name: 'bool',   format: 'boolean') }
      let(:select_field) { FactoryGirl.create(:custom_field, name: 'select', format: 'select') }

      let!(:select_option1) { select_field.options.create!(label: 'aaa') }
      let!(:select_option2) { select_field.options.create!(label: 'bbb') }

      let(:import) do
        FactoryGirl.create(
          :import,
          status: 'active',
          match_strategy: 'by_id_only',
          mappings: {
            'id'    => 'id',
            'first' => 'first_name',
            'foo'   => string_field.slug,
            'date'  => date_field.slug,
            'bool'  => bool_field.slug,
            'sel'   => select_field.slug
          }
        )
      end

      let!(:person) { FactoryGirl.create(:person) }
      let!(:row) { create_row(id: person.id, first: 'Changed', foo: 'bar', date: '2017-01-01', bool: '1', sel: 'Aaa') }

      it 'updates custom fields' do
        expect do
          subject.execute
        end.to change {
          person.reload.fields
        }.from(
          {}
        ).to(
          string_field.id => 'bar',
          date_field.id   => '2017-01-01',
          bool_field.id   => '1',
          select_field.id => select_option1.id.to_s
        )
      end

      it 'records changes' do
        expect(row.attribute_changes).to be_nil
        subject.execute
        expect(row.reload.updated_person?).to eq(true)
        expect(row.attribute_changes['person']).to eq(
          'first_name'       => %w(John Changed),
          string_field.slug  => [nil, 'bar'],
          date_field.slug    => [nil, '2017-01-01'],
          bool_field.slug    => [nil, '1'],
          select_field.slug  => [nil, select_option1.id.to_s]
        )
      end

      context 'when only a custom field is modified' do
        let!(:row) do
          create_row(id: person.id, foo: 'changed')
        end

        it 'records that the person was changed' do
          expect(row.attribute_changes).to be_nil
          subject.execute
          expect(row.reload.updated_person?).to eq(true)
        end
      end

      context 'when a select field option cannot be matched' do
        let!(:row) do
          create_row(id: person.id, sel: 'xxx')
        end

        it 'does not update and records the error message' do
          subject.execute
          expect(row.reload.attributes).to include(
            'created_person'   => false,
            'created_family'   => false,
            'updated_person'   => false,
            'updated_family'   => false,
            'errored'          => true,
            'attribute_errors' => {
              select_field.slug => 'Option with label "xxx" could not be found.'
            }
          )
        end
      end

      context 'when a date just has slashes' do
        let!(:row) { create_row(id: person.id, first: 'Changed', foo: 'bar', date: ' / / ', bool: '1') }

        it 'treats the date as nil' do
          expect do
            subject.execute
          end.to change {
            person.reload.fields
          }.from(
            {}
          ).to(
            string_field.id => 'bar',
            date_field.id   => nil,
            bool_field.id   => '1'
          )
        end
      end
    end

    context 'given dangerous attribute mappings' do
      let(:import) do
        FactoryGirl.create(
          :import,
          status: 'active',
          match_strategy: 'by_id_only',
          mappings: {
            'id'       => 'id',
            'first'    => 'first_name',
            'site_id'  => 'site_id',
            'password' => 'encrypted_password',
            'consent'  => 'parental_consent'
          }
        )
      end

      let!(:person) { FactoryGirl.create(:person) }
      let!(:row) { create_row(id: person.id, first: 'Changed', site_id: '100', password: 'pwnd', consent: 'pwnd') }

      it 'does not update anything dangerous' do
        expect do
          subject.execute
        end.not_to change {
          person.reload.attributes.select { |k| %w(site_id encrypted_password parental_consent).include?(k) }
        }
        expect(row.reload.updated_person).to eq(true)
        expect(person.reload.first_name).to eq('Changed')
      end
    end

    context 'given the job fails mid-way and is restarted' do
      let!(:person)        { FactoryGirl.create(:person) }
      let!(:completed_row) { create_row({ id: person.id }, status: :imported) }
      let!(:pending_row)   { create_row({ id: person.id, first: 'Changed' }, status: :previewed) }

      it 'only imports the pending rows' do
        expect do
          subject.execute
        end.not_to change {
          completed_row.reload.attributes
        }
        expect(pending_row.reload.updated_person).to eq(true)
      end
    end

    context 'given the match strategy is by_id_only' do
      before do
        import.match_strategy = :by_id_only
        import.save!
      end

      context 'given a row with an existing person id and existing family id' do
        let(:family)  { FactoryGirl.create(:family) }
        let!(:person) { FactoryGirl.create(:person, first_name: 'John', last_name: 'Smith', email: 'old@example.com') }

        context 'given the person attributes changed' do
          let!(:row) { create_row(id: person.id, first: 'John', last: 'Jones', email: 'new@example.com', fam_id: person.family_id) }

          before { subject.execute }

          it 'updates the person but not the family' do
            expect(row.reload.attributes).to include(
              'created_person' => false,
              'created_family' => false,
              'updated_person' => true,
              'updated_family' => false
            )
          end

          it 'records how the records were matched' do
            expect(row.reload.matched_person_by_id?).to eq(true)
            expect(row.matched_family_by_id?).to eq(true)
          end

          it 'records what attributes changed' do
            expect(row.reload.attribute_changes).to eq(
              'person' => {
                'last_name' => %w(Smith Jones),
                'email'     => ['old@example.com', 'new@example.com']
              },
              'family' => {}
            )
          end

          it 'updates the status of the rows' do
            expect(row.reload.attributes).to include(
              'status' => 'imported'
            )
          end

          it 'does not set the email_changed flag' do
            expect(person.reload.email_changed?).to eq(false)
          end
        end

        context 'given the person attributes are invalid' do
          let!(:row) { create_row(id: person.id, first: '', last: 'Jones', fam_id: family.id) }

          before { subject.execute }

          it 'does not update and records the error message' do
            expect(row.reload.attributes).to include(
              'created_person'   => false,
              'created_family'   => false,
              'updated_person'   => false,
              'updated_family'   => false,
              'attribute_errors' => { 'first_name' => 'The person must have a first name.' },
              'errored'          => true
            )
          end
        end

        context 'given the family attributes are invalid' do
          let!(:row) { create_row(id: person.id, first: 'John', last: 'Jones', fam_id: family.id, fam_name: '') }

          before { subject.execute }

          it 'does not update and records the error message' do
            expect(row.reload.attributes).to include(
              'created_person'   => false,
              'created_family'   => false,
              'updated_person'   => false,
              'updated_family'   => false,
              'attribute_errors' => { 'family' => { 'name' => 'The family must have a name.' } },
              'errored'          => true
            )
          end
        end

        context "given the the person's email address has changed" do
          let!(:row) { create_row(id: person.id, first: 'John', last: 'Jones', email: 'changed2@example.com', fam_id: person.family_id) }

          before do
            person.email = 'changed1@example.com'
            person.email_changed = true
            person.save!
            subject.execute
          end

          it 'updates the person' do
            expect(row.reload.attributes).to include(
              'created_person' => false,
              'created_family' => false,
              'updated_person' => true,
              'updated_family' => false
            )
          end

          it 'does not change the email address and does not clear the email_changed flag' do
            expect(person.reload.attributes).to include(
              'email' => 'changed1@example.com',
              'email_changed' => true
            )
          end

          it 'records what attributes changed' do
            expect(row.reload.attribute_changes).to eq(
              'person' => {
                'last_name' => %w(Smith Jones)
              },
              'family' => {}
            )
          end
        end

        context "given the the person's email address has changed and the import matches it" do
          let!(:row) { create_row(id: person.id, first: 'John', last: 'Jones', email: 'changed1@example.com', fam_id: person.family_id) }

          before do
            person.email = 'changed1@example.com'
            person.email_changed = true
            person.save!
            subject.execute
          end

          it 'updates the person' do
            expect(row.reload.attributes).to include(
              'created_person' => false,
              'created_family' => false,
              'updated_person' => true,
              'updated_family' => false
            )
          end

          it 'clears the email_changed flag' do
            expect(person.reload.attributes).to include(
              'email' => 'changed1@example.com',
              'email_changed' => false
            )
          end

          it 'records what attributes changed' do
            expect(row.reload.attribute_changes).to eq(
              'person' => {
                'last_name'     => %w(Smith Jones),
                'email_changed' => [true, false]
              },
              'family' => {}
            )
          end
        end

        context "given the the person's email address has changed and the import has overwrite_changed_emails=true" do
          let!(:row) { create_row(id: person.id, first: 'John', last: 'Jones', fam_id: family.id, email: 'changed2@example.com') }

          before do
            import.overwrite_changed_emails = true
            import.save!
            person.email = 'changed1@example.com'
            person.email_changed = true
            person.save!
            subject.execute
          end

          it 'updates the person' do
            expect(row.reload.attributes).to include(
              'created_person' => false,
              'created_family' => false,
              'updated_person' => true,
              'updated_family' => false
            )
          end

          it 'updates the email address and clears the email_changed flag' do
            expect(person.reload.attributes).to include(
              'email' => 'changed2@example.com',
              'email_changed' => false
            )
          end
        end
      end

      context 'given a row with an existing person id and new family id' do
        let!(:person) { FactoryGirl.create(:person) }
        let!(:family) { person.family }

        let!(:row) { create_row(id: person.id, first: 'John', last: 'Jones', fam_id: 'new123', fam_name: 'John Jones') }

        before { subject.execute }

        it 'updates the person and creates the family' do
          expect(person.reload.family).not_to eq(family)
          expect(person.family.reload.name).to eq('John Jones')
          expect(row.reload.attributes).to include(
            'created_person' => false,
            'created_family' => true,
            'updated_person' => true,
            'updated_family' => false
          )
        end

        it 'records what attributes changed' do
          expect(row.reload.attribute_changes).to eq(
            'person' => {
              'last_name' => %w(Smith Jones),
              'family_id' => [family.id, person.reload.family_id]
            },
            'family' => {}
          )
        end
      end

      context 'given a row with a new family with an address' do
        let!(:person) { FactoryGirl.create(:person) }
        let!(:family) { person.family }

        let!(:row) do
          create_row(
            id: person.id,
            first: 'John',
            last: 'Jones',
            fam_id: 'new123',
            fam_name: 'John Jones',
            address: '650 S. Peoria Ave.',
            city: 'Tulsa',
            state: 'OK',
            zip: '74120'
          )
        end

        before do
          subject.execute
        end

        it 'geocodes the family' do
          expect(person.reload.family.attributes).to include(
            'latitude'  => within(0.001).of(40.7143),
            'longitude' => within(0.001).of(-74.0059)
          )
        end
      end

      context 'given a row with an existing person id and no family id' do
        let!(:person) { FactoryGirl.create(:person) }
        let!(:family) { person.family }

        let!(:row) { create_row(id: person.id, first: 'John', last: 'Jones', fam_name: 'John Jones') }

        before { subject.execute }

        it 'updates the person and updates the family' do
          expect(person.reload.family).to eq(family)
          expect(person.family.reload.name).to eq('John Jones')
          expect(row.reload.attributes).to include(
            'created_person' => false,
            'created_family' => false,
            'updated_person' => true,
            'updated_family' => true
          )
        end

        it 'records what attributes changed' do
          expect(row.reload.attribute_changes).to eq(
            'person' => {
              'last_name' => %w(Smith Jones)
            },
            'family' => {
              'name'      => ['John Smith', 'John Jones'],
              'last_name' => %w(Smith Jones)
            }
          )
        end
      end

      context 'given a row with an existing person legacy_id and no family legacy_id' do
        let!(:person) { FactoryGirl.create(:person, legacy_id: 1000) }
        let!(:family) { person.family }

        let!(:row) { create_row(legacy_id: 1000, first: 'John', last: 'Jones', fam_name: 'John Jones') }

        before { subject.execute }

        it 'updates the person and updates the family' do
          expect(row.reload.attributes).to include(
            'created_person' => false,
            'created_family' => false,
            'updated_person' => true,
            'updated_family' => true
          )
          expect(row.person).to eq(person)
          expect(row.family).to eq(family)
        end
      end

      context 'given a row with an existing person legacy_id and a new family legacy_id' do
        let!(:person) { FactoryGirl.create(:person, legacy_id: 1000) }

        let!(:row) { create_row(legacy_id: 1000, first: 'John', last: 'Jones', fam_name: 'John Jones', fam_lid: 5000) }

        before { subject.execute }

        it 'updates the person and creates the family' do
          expect(row.reload.attributes).to include(
            'created_person' => false,
            'created_family' => true,
            'updated_person' => true,
            'updated_family' => false
          )
          expect(row.person).to eq(person)
          expect(row.family).not_to eq(person.family)
        end
      end

      context 'given a new row with a blank family id' do
        let!(:row) { create_row(first: 'John', last: 'Jones', fam_id: '', fam_name: 'John Jones') }

        before { subject.execute }

        it 'creates the person and the family' do
          expect(row.reload.attributes).to include(
            'created_person' => true,
            'created_family' => true,
            'updated_person' => false,
            'updated_family' => false
          )
        end
      end

      context 'given 2 new rows with the same new family id' do
        let!(:row1) { create_row(first: 'John', last: 'Jones', fam_id: '100', fam_name: 'John & Jane Jones') }
        let!(:row2) { create_row(first: 'Jane', last: 'Jones', fam_id: '100', fam_name: 'John & Jane Jones') }

        before { subject.execute }

        it 'creates the first person and family' do
          expect(row1.reload.attributes).to include(
            'created_person' => true,
            'created_family' => true,
            'updated_person' => false,
            'updated_family' => false
          )
        end

        it 'creates the second person but not the family' do
          expect(row2.reload.attributes).to include(
            'created_person' => true,
            'created_family' => false,
            'updated_person' => false,
            'updated_family' => false
          )
        end
      end

      context 'given a new row with an existing family id' do
        let(:family) { FactoryGirl.create(:family) }
        let!(:row)   { create_row(first: 'John', last: 'Jones', fam_id: family.id) }

        before { subject.execute }

        it 'creates the person but not the family' do
          expect(row.reload.attributes).to include(
            'created_person' => true,
            'created_family' => false,
            'updated_person' => false,
            'updated_family' => false
          )
        end
      end

      context 'given a row with an existing id and a relationships string' do
        let!(:person)  { FactoryGirl.create(:person) }
        let!(:person2) { FactoryGirl.create(:person, legacy_id: 1001) }
        let!(:person3) { FactoryGirl.create(:person, legacy_id: 1002) }
        let!(:row)     { create_row(id: person.id, first: 'John', last: 'Jones', rel: '1001[son],1002[daughter]') }
        let!(:rel1)    { person.relationships.create!(related: person2, name: 'son') }
        let!(:rel2)    { person.relationships.create!(related: person2, name: 'other', other_name: 'Delete Me') }

        before do
          subject.execute
        end

        it 'creates the new relationship' do
          expect(row.reload.updated_person).to eq(true)
          expect(person.relationships.count).to eq(2)
          expect { rel2.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'given the match strategy is by_name' do
      before do
        import.match_strategy = :by_name
        import.save!
      end

      context 'given a row with an existing person name and existing family name' do
        let(:family) { FactoryGirl.create(:family, name: 'John Jones', last_name: 'Jones') }
        let(:person) { FactoryGirl.create(:person, first_name: 'John', last_name: 'Jones', family: family) }

        context 'given the attributes are valid and the data is unchanged' do
          let!(:row) { create_row(first: person.first_name, last: person.last_name, fam_name: family.name) }

          before { subject.execute }

          it 'does not update the person or the family' do
            expect(row.reload.attributes).to include(
              'created_person' => false,
              'created_family' => false,
              'updated_person' => false,
              'updated_family' => false
            )
          end

          it 'records the matched person and family' do
            expect(row.reload.person).to eq(person)
            expect(row.family).to eq(family)
          end

          it 'records how the records were matched' do
            expect(row.reload.matched_person_by_name?).to eq(true)
            expect(row.matched_family_by_name?).to eq(true)
          end
        end

        context 'given the attributes are valid and the person changed' do
          let!(:row) { create_row(first: person.first_name, last: person.last_name, email: 'new@a.com', fam_name: family.name) }

          before { subject.execute }

          it 'updates the person but not the family' do
            expect(row.reload.attributes).to include(
              'created_person' => false,
              'created_family' => false,
              'updated_person' => true,
              'updated_family' => false
            )
          end

          it 'records the matched person and family' do
            expect(row.reload.person).to eq(person)
            expect(row.family).to eq(family)
          end
        end

        context 'given the person attributes are invalid' do
          let!(:row) { create_row(first: person.first_name, last: person.last_name, email: 'bad', fam_name: family.name, fam_lname: 'Changed') }

          before { subject.execute }

          it 'does not update and records the error message' do
            expect(row.reload.attributes).to include(
              'created_person'   => false,
              'created_family'   => false,
              'updated_person'   => false,
              'updated_family'   => false,
              'attribute_errors' => { 'email' => 'The email address is not formatted correctly (something@example.com).' },
              'errored'          => true
            )
          end

          it 'records the matched person and family' do
            expect(row.reload.person).to eq(person)
            expect(row.family).to eq(family)
          end
        end

        context 'given the family attributes are invalid' do
          let!(:row) { create_row(first: person.first_name, last: person.last_name, fam_name: family.name, fam_lname: '') }

          before { subject.execute }

          it 'does not update and records the error message' do
            expect(row.reload.attributes).to include(
              'created_person'   => false,
              'created_family'   => false,
              'updated_person'   => false,
              'updated_family'   => false,
              'attribute_errors' => { 'family' => { 'last_name' => 'The family must have a last name.' } },
              'errored'          => true
            )
          end

          it 'records the matched person and family' do
            expect(row.reload.person).to eq(person)
            expect(row.family).to eq(family)
          end
        end
      end

      context 'given a row with an existing person name and new family name and family id present' do
        let!(:person) { FactoryGirl.create(:person, first_name: 'John', last_name: 'Jones') }

        let!(:row) { create_row(first: person.first_name, last: person.last_name, fam_id: 'new', fam_name: 'John Jones') }

        before { subject.execute }

        it 'updates the person and creates the family' do
          expect(row.reload.attributes).to include(
            'created_person' => false,
            'created_family' => true,
            'updated_person' => true,
            'updated_family' => false
          )
        end

        it 'records the matched person and the new family' do
          expect(row.reload.person).to eq(person)
          expect(row.family.attributes).to include(
            'name' => 'John Jones'
          )
        end
      end

      context 'given a new row with invalid person attributes and new family name' do
        let!(:row) { create_row(first: 'John', last: '', fam_name: 'John Jones') }

        before { subject.execute }

        it 'does not update the person or family' do
          expect(row.reload.attributes).to include(
            'created_person' => false,
            'created_family' => false,
            'updated_person' => false,
            'updated_family' => false
          )
        end
      end

      context 'given a new row and create_as_active is true' do
        let!(:row) { create_row(first: 'John', last: 'Jones', fam_name: 'John Jones') }

        before do
          import.create_as_active = true
          import.save!
          subject.execute
        end

        it 'creates the person and sets them active' do
          expect(row.reload.person).to be_active
        end
      end

      context 'given 3 new rows with 2 of them having the same family name' do
        let!(:row1) { create_row(first: 'Bob',  last: 'Jones', fam_name: 'Bob Jones') }
        let!(:row2) { create_row(first: 'John', last: 'Jones', fam_name: 'John & Jane Jones') }
        let!(:row3) { create_row(first: 'Jane', last: 'Jones', fam_name: 'John & Jane Jones') }

        before { subject.execute }

        it 'creates the first person and family' do
          expect(row1.reload.person.attributes).to include(
            'first_name' => 'Bob',
            'last_name'  => 'Jones'
          )
          expect(row1.person.family.attributes).to include(
            'name' => 'Bob Jones'
          )
          expect(row1.attributes).to include(
            'created_person' => true,
            'created_family' => true,
            'updated_person' => false,
            'updated_family' => false
          )
        end

        it 'creates the second person and family' do
          expect(row2.reload.person.attributes).to include(
            'first_name' => 'John',
            'last_name'  => 'Jones'
          )
          expect(row2.person.family.attributes).to include(
            'name' => 'John & Jane Jones'
          )
          expect(row2.attributes).to include(
            'created_person' => true,
            'created_family' => true,
            'updated_person' => false,
            'updated_family' => false
          )
        end

        it 'creates the third person but not the family' do
          expect(row3.reload.person.attributes).to include(
            'first_name' => 'Jane',
            'last_name'  => 'Jones'
          )
          expect(row3.person.family.attributes).to include(
            'name' => 'John & Jane Jones'
          )
          expect(row3.person.family).to eq(row2.reload.person.family)
          expect(row3.attributes).to include(
            'created_person'   => true,
            'created_family'   => false,
            'updated_person'   => false,
            'updated_family'   => false,
            'attribute_errors' => {}
          )
        end
      end

      context 'given a new row with an existing family id' do
        let(:family) { FactoryGirl.create(:family) }
        let!(:row)   { create_row(first: 'John', last: 'Jones', fam_name: family.name) }

        before { subject.execute }

        it 'creates the person but not the family' do
          expect(row.reload.attributes).to include(
            'created_person' => true,
            'created_family' => false,
            'updated_person' => false,
            'updated_family' => false
          )
        end
      end

      context 'given a new row with a blank family name' do
        let!(:row) { create_row(first: 'John', last: 'Jones', fam_name: '') }

        before { subject.execute }

        it 'does not create the person or the family' do
          expect(row.reload.attributes).to include(
            'created_person' => false,
            'created_family' => false,
            'updated_person' => false,
            'updated_family' => false,
            'errored'        => true
          )
        end

        it 'saves the error message' do
          expect(row.reload.attribute_errors).to eq(
            'family' => {
              'name'      => 'The family must have a name.',
              'last_name' => 'The family must have a last name.'
            }
          )
        end
      end

      context 'given a row with a blank id' do
        let!(:family) { FactoryGirl.create(:family, name: 'John Jones') }
        let!(:person) { FactoryGirl.create(:person, first_name: 'John', last_name: 'Jones', family: family) }

        let!(:row) { create_row(id: '', first: person.first_name, last: person.last_name, email: 'a@new.com', fam_id: '', fam_name: family.name, fam_lname: 'Changed') }

        before { subject.execute }

        it 'updates the person and the family' do
          expect(row.reload.attributes).to include(
            'created_person'   => false,
            'created_family'   => false,
            'updated_person'   => true,
            'updated_family'   => true,
            'attribute_errors' => {}
          )
        end

        it 'records the matched person and familiy' do
          expect(row.reload.person).to eq(person)
          expect(row.family).to eq(family)
        end
      end

      context 'given a row with a birthday that contains only slashes' do
        let(:family) { FactoryGirl.create(:family, name: "John Jones") }
        let!(:row) { create_row(first: 'Jimmy', last: 'Jones', fam_name: family.name, birthday: '/ /') }

        before { subject.execute }

        it 'creates the person and sets the birthday to blank' do
          expect(row.reload.attributes).to include(
            'created_person' => true,
            'created_family' => false,
            'updated_person' => false,
            'errored'        => false
          )
          expect(subject.attributes_for_person(row)).to include(
            'birthday' => nil
          )
        end
      end
    end
  end
end
