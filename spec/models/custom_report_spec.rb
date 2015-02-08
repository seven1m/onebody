require_relative '../rails_helper'

describe CustomReport do
  subject { CustomReport.new }
  before { @custom_report = FactoryGirl.create(:custom_report) }

  context '#title' do
    context 'title is blank' do
      before { @custom_report.title = nil }
      it { should be_invalid }
    end

    context 'title is too long' do
     before { @custom_report.title = 'a' * 51 }
     it { should be_invalid }
    end
  end

  context '#body' do
    context 'body is blank' do
      before { @custom_report.body = nil }
      it { should be_invalid }
    end
  end

  context 'Save a Valid Record' do
    before do
      @custom_report.save!
    end

    it 'should return a saved record' do
      expect(@custom_report).to eq(CustomReport.first)
    end
  end

  context '#category' do

    it 'should be invalid' do
      @custom_report.category = nil
      expect(@custom_report).to be_invalid
      expect(@custom_report.errors.messages[:category])
        .to include(I18n.t('activerecord.errors.models.custom_report.attributes.category.inclusion'))
    end

    it 'should be valid' do
      @custom_report.category = '1'
      expect(@custom_report).to be_valid
    end
  end

  context '#filters' do
    it 'should be invalid' do
      @custom_report.filters = 'a strange string'
      expect(@custom_report).to be_invalid
    end

    it 'should be valid' do
      @custom_report.filters = 'gender:Male'
      expect(@custom_report).to be_valid
    end

    it 'can be empty' do
      @custom_report.filters = nil
      expect(@custom_report).to be_valid
    end

  end

  context '#multiple' do
    context 'invalid filters' do
      before do
        @custom_report.filters = 'gender:Male first_name:Jim'
      end
      it 'should raise an error' do
        @custom_report.save
        expect(@custom_report.errors.messages[:filters])
          .to include(I18n.t('reports.custom_reports.validation.filters'))
      end
    end

    context 'valid filters' do
      before do
        @custom_report.filters = 'gender:Male; first_name:Jim'
      end

      it 'should be valid' do
        expect(@custom_report).to be_valid
      end

      it 'should save sucessfully' do
        @custom_report.save
        expect(@custom_report).to eq(CustomReport.first)
      end
    end
  end

  context 'Vaildations' do

    before do
      @person = FactoryGirl.create(:person)
    end

    context 'Arrays' do

      it 'should be callable as Arrays' do
        expect(@custom_report.person_field_list).to be_a(Array)
        expect(@custom_report.family_field_list).to be_a(Array)
        expect(@custom_report.group_field_list).to be_a(Array)
        expect(@custom_report.first_last_list).to be_a(Array)
        expect(@custom_report.name_list).to be_a(Symbol)
        expect(@custom_report.task_list).to be_a(Array)
      end

      it 'should include at least one element' do
        expect(@custom_report.person_field_list.first).not_to be_nil
        expect(@custom_report.family_field_list.last).not_to be_nil
        expect(@custom_report.group_field_list.first).not_to be_nil
        expect(@custom_report.first_last_list.last).not_to be_nil
        expect(@custom_report.task_list.last).not_to be_nil
      end

    end

    context 'A Person' do
      before do
        @custom_report = FactoryGirl.create(:custom_report)
        @report_data = @custom_report.data_set(@custom_report.category)
      end

      it { should be }

      it 'should contain the person' do
        expect(@report_data[0].flatten[1]['first_name'])
          .to eq(@person.first_name)
      end

      it 'should have associated family data' do
        expect(@report_data[0].flatten[1]['family']['name'])
          .to eq(@person.family.name)
      end
    end

    context 'The Group ' do
      before do
        @group = FactoryGirl.create(:group,
                                    name: 'Doe Group',
                                    creator: @person,
                                    category: 'Small Groups')
        @group.memberships.create(person: @person, admin: true)
        @group_member = FactoryGirl.create(:person)
        @group.memberships.create(person: @group_member)
      end

      context 'is valid and ' do
        before do
          @custom_report = FactoryGirl.create(:custom_report,
                                              category: '3',
                                              filters: '')
          @report_data = @custom_report.data_set(@custom_report.category)
        end

        it 'contains group data ' do
          expect(@report_data).to be
          expect(@report_data[0].to_h.assoc('group')).to be_a(Array)
          expect(@report_data[0].to_h['group']['name']).to eq(@group.name)
        end

        it 'should contain two different members' do
          expect(@report_data[0].to_h['group']['people'][0]['email']).to be
          expect(@report_data[0].to_h['group']['people'][1]['email']).to be
          expect(@report_data[0].to_h['group']['people'][0]['email'])
            .not_to eq(@report_data[0].to_h['group']['people'][1]['email'])
        end
      end

      context 'is empty ' do
        before do
          @custom_report = FactoryGirl.create(:custom_report,
                                              category: '3',
                                              filters: 'category:Bad Data')
          @report_data = @custom_report.data_set(@custom_report.category)
        end

        it 'when passed non-matching filter' do
          expect(@report_data).to be
          expect(@report_data[0].to_h).to be_empty
        end
      end

      context 'is populated ' do
        before do
          @custom_report = FactoryGirl.create(:custom_report,
                                              category: '3',
                                              filters: 'category:Small Groups')
          @report_data = @custom_report.data_set(@custom_report.category)
        end

        it 'when passed a matching filter' do
          expect(@report_data).to be
          expect(@report_data[0].to_h).to be
          expect(@report_data[0].to_h['group']['name']).to eq(@group.name)
        end
      end
    end

    context 'A Family ' do
      before do
        @family = FactoryGirl.create(:family,
                                     address1: '100 Test Street',
                                     address2: 'Testville',
                                     city: 'Cunthorpe',
                                     state: 'OH',
                                     zip: '2358',
                                     country: 'NZ')
        @custom_report = FactoryGirl.create(:custom_report,
                                            category: '2',
                                            filters: 'state:OH')
        @adult1 = FactoryGirl.create(:person,
                                     family: @family,
                                     child: false,
                                     first_name: 'Maxwell',
                                     last_name: 'Smart')
        @adult2 = FactoryGirl.create(:person,
                                     family: @family,
                                     child: false,
                                     first_name: 'Agent',
                                     last_name: '99',
                                     gender: 'Female')
        @family.name = @family.suggested_name
        @family.save!

      end

      context 'given a family with two adults' do
        before do
          @report_data = @custom_report.data_set(@custom_report.category)
        end

        it 'should contain valid data' do
          expect(@report_data[0].to_h).to be
        end

        it 'should contain a family address' do
          expect(@report_data[0].to_h['family']['address1'])
            .to eq(@family.address1)
        end

        it 'should contain two different people' do
          expect(@report_data[0].to_h['family']['people'][0]['gender'])
            .to eq(@adult1.gender)
          expect(@report_data[0].to_h['family']['people'][1]['gender'])
            .to eq(@adult2.gender)
        end
      end
    end

    context 'SQL Array Values' do
      before do
        @custom_report = FactoryGirl.create(
                           :custom_report,
                           category: '3',
                           filters: 'name:Doe Group; some:rubbish')
        @array = @custom_report.build_sql_array(@custom_report.group_field_list)
      end

      it 'should include valid filters' do
        expect(@array.flatten).to include('name')
      end

      it 'should discard invalid filters' do
        expect(@array.flatten).not_to include('rubbish')
      end

    end

    context 'The Where Clause ' do
      before do
        @custom_report = FactoryGirl.create(
                           :custom_report,
                           category: '3',
                           filters: 'name:Doe Group; meets:As Announced')
        @array = @custom_report.build_sql_array(@custom_report.group_field_list)
        @where = @custom_report.process_where_clause(@array)
      end

      it 'should include valid filters' do
        expect(@array.flatten).to include('name')
      end

      it 'should have a string as its first parameter' do
        expect(@where[0]).to be_a(String)
      end

      it 'should have a hash as its second parameter' do
        expect(@where[1]).to be_a(Hash)
      end

      it 'should include a meets parameter' do
        expect(@where[0]).to include('meets = :meets')
      end

      it 'should include a meets bind' do
        expect(@where[1][:meets]).to be
        expect(@where[1][:meets]).to eq('As Announced')
      end
    end
  end

end
