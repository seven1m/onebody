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

end
