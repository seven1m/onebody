require_relative '../spec_helper'

describe Family do

  describe 'Barcodes' do
    it 'should not allow the same barcode id to be assigned to two families' do
      @family = FactoryGirl.create(:family, barcode_id: '1234567890')
      @family2 = FactoryGirl.build(:family)
      @family2.barcode_id = '1234567890'
      @family2.save
      expect(@family2.errors[:barcode_id]).to be
    end

    it 'should not allow the same alternate barcode id to be assigned to two families' do
      @family = FactoryGirl.create(:family, alternate_barcode_id: '1234567890')
      @family2 = FactoryGirl.build(:family)
      @family2.alternate_barcode_id = '1234567890'
      @family2.save
      expect(@family2.errors[:alternate_barcode_id]).to be
    end

    it 'should not allow the same id to be assigned to a barcode_id and an alternate_barcode_id on different families' do
      # alternate was there first
      @family = FactoryGirl.create(:family, alternate_barcode_id: '1234567890')
      @family2 = FactoryGirl.build(:family)
      @family2.barcode_id = '1234567890'
      @family2.save
      expect(@family2.errors[:barcode_id]).to be
      # main id was there first
      @family3 = FactoryGirl.create(:family, barcode_id: '9876543210')
      @family4 = FactoryGirl.build(:family)
      @family4.alternate_barcode_id = '9876543210'
      @family4.save
      expect(@family4.errors[:alternate_barcode_id]).to be
    end

    it 'should not allow a barcode_id and alternate_barcode_id to be the same' do
      # on existing record
      @family = FactoryGirl.build(:family)
      @family.barcode_id = '1234567890'
      @family.save
      expect(@family).to be_valid
      @family.alternate_barcode_id = '1234567890'
      @family.save
      expect(@family.errors[:barcode_id]).to be_any
      # on new record
      @family2 = FactoryGirl.build(:family)
      @family2.barcode_id = '1231231231'
      @family2.alternate_barcode_id = '1231231231'
      @family2.save
      expect(@family2.errors[:barcode_id]).to be_any
    end

    it 'should allow both barcode_id and alternate_barcode_id to be nil' do
      @family = FactoryGirl.build(:family)
      @family.barcode_id = ''
      @family.alternate_barcode_id = nil
      @family.save
      expect(@family.errors[:barcode_id]).to eq([])
      expect(@family.barcode_id).to eq(nil)
      expect(@family.alternate_barcode_id).to eq(nil)
    end
  end

  describe '#suggested_name' do
    subject { FactoryGirl.create(:family) }

    context 'given a new family' do
      it 'returns nil' do
        expect(subject.suggested_name).to be_nil
      end
    end

    context 'given a family with one adult' do
      let!(:adult) { FactoryGirl.create(:person, family: subject, child: false, first_name: "Tim", last_name: "Morgan") }

      it 'returns name of first adult' do
        expect(subject.suggested_name).to eq("Tim Morgan")
      end
    end

    context 'given a family with two adults' do
      let!(:adult1) { FactoryGirl.create(:person, family: subject, child: false, first_name: "Tim", last_name: "Morgan") }
      let!(:adult2) { FactoryGirl.create(:person, family: subject, child: false, first_name: "Jennie", last_name: "Morgan") }

      it 'returns first names of both adults and common last name' do
        expect(subject.suggested_name).to eq("Tim & Jennie Morgan")
      end

      context 'given the adults have different last names' do
        before { adult2.last_name = 'Smith'; adult2.save! }

        it 'returns full name of both adults' do
          expect(subject.suggested_name).to eq("Tim Morgan & Jennie Smith")
        end
      end

      context 'given one of the adults is deleted' do
        before { adult2.destroy }

        it 'returns full name only first adult' do
          expect(subject.suggested_name).to eq("Tim Morgan")
        end
      end
    end

    context 'given a family with three adults' do
      let!(:adult1) { FactoryGirl.create(:person, family: subject, child: false, first_name: "Tim", last_name: "Morgan") }
      let!(:adult2) { FactoryGirl.create(:person, family: subject, child: false, first_name: "Jennie", last_name: "Morgan") }
      let!(:adult3) { FactoryGirl.create(:person, family: subject, child: false, first_name: "Ruth", last_name: "Morgan") }

      it 'returns first names of first two adults and common last name' do
        expect(subject.suggested_name).to eq("Tim & Jennie Morgan")
      end
    end
  end

  describe '#reorder' do
    context 'given a family with three people' do
      subject { FactoryGirl.create(:family) }

      let!(:head)   { FactoryGirl.create(:person, family: subject, child: false, first_name: "Tim",    last_name: "Morgan") }
      let!(:spouse) { FactoryGirl.create(:person, family: subject, child: false, first_name: "Jennie", last_name: "Morgan") }
      let!(:child)  { FactoryGirl.create(:person, family: subject, child: true,  first_name: "Mac",    last_name: "Morgan") }

      context 'given direction up' do
        before do
          subject.reorder_person(spouse, 'up')
        end

        it 'changes the order' do
          expect(spouse.reload.sequence).to eq(1)
          expect(head.reload.sequence).to eq(2)
          expect(child.reload.sequence).to eq(3)
        end
      end

      context 'given direction up and person is already first' do
        before do
          subject.reorder_person(head, 'up')
        end

        it 'does not change the order' do
          expect(head.reload.sequence).to eq(1)
          expect(spouse.reload.sequence).to eq(2)
          expect(child.reload.sequence).to eq(3)
        end
      end

      context 'given direction up and sequences are invalid and there is a deleted person' do
        before do
          child.destroy
          @new_child = FactoryGirl.create(:person, family: subject, child: true)
          subject.people.update_all(sequence: 2)
          expect(subject.people.reload.undeleted).to eq([head, spouse, @new_child]) # database order
          subject.reorder_person(@new_child.reload, 'up')
        end

        it 'fixes sequence numbers' do
          expect(head.reload.sequence).to eq(1)
          expect(@new_child.reload.sequence).to eq(2)
          expect(spouse.reload.sequence).to eq(3)
        end
      end

      context 'given direction down' do
        before do
          subject.reorder_person(spouse, 'down')
        end

        it 'changes the order' do
          expect(head.reload.sequence).to eq(1)
          expect(child.reload.sequence).to eq(2)
          expect(spouse.reload.sequence).to eq(3)
        end
      end

      context 'given direction down and person is already last' do
        before do
          subject.reorder_person(child, 'down')
        end

        it 'does not change the order' do
          expect(head.reload.sequence).to eq(1)
          expect(spouse.reload.sequence).to eq(2)
          expect(child.reload.sequence).to eq(3)
        end
      end

      context 'given invalid direction' do
        before do
          subject.reorder_person(child, 'sideways')
        end

        it 'does not change the order' do
          expect(head.reload.sequence).to eq(1)
          expect(spouse.reload.sequence).to eq(2)
          expect(child.reload.sequence).to eq(3)
        end
      end
    end
  end

  context '#name' do
    before do
      @family = FactoryGirl.create(:family)
    end

    context 'family name is empty' do
      before do
        @family.name = nil
      end

      it 'should be invalid' do
        expect(@family).to be_invalid
      end
    end
  end

  context '#last_name' do
    before do
      @family = FactoryGirl.create(:family)
    end

    context 'family last name is empty' do
      before do
        @family.last_name = nil
      end

      it 'should be invalid' do
        expect(@family).to be_invalid
      end
    end
  end
end
