require 'rails_helper'

describe Document, type: :model do
  def file(name, content_type)
    Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files', name), content_type, true)
  end

  let(:doc) { file('word.doc', 'application/msword') }
  let(:pdf) { file('attachment.pdf', 'application/pdf') }
  let(:jpg) { file('image.jpg', 'image/jpg') }
  let(:bad_pdf) { file('bad.pdf', 'application/pdf') }

  subject { FactoryGirl.build(:document) }

  describe '#image?' do
    context 'given a JPG image' do
      before do
        subject.file = jpg
        subject.save!
      end

      it 'returns true' do
        expect(subject.image?).to eq(true)
      end
    end

    context 'given a PDF file' do
      before do
        subject.file = pdf
        subject.save!
      end

      it 'returns false' do
        expect(subject.image?).to eq(false)
      end
    end
  end

  describe '#build_preview' do
    context 'given a DOC file' do
      before do
        subject.file = doc
        subject.save!
      end

      it 'does not create a preview' do
        expect(subject.preview).not_to be_present
      end
    end

    context 'given a JPG image' do
      before do
        subject.file = jpg
        subject.save!
      end

      it 'creates a preview' do
        expect(subject.preview).to be_present
      end
    end

    context 'given a PDF file' do
      before do
        subject.file = pdf
        subject.save!
      end

      it 'creates a preview image' do
        expect(subject.preview).to be_present
      end
    end

    context 'given a corrupt PDF file' do
      before do
        subject.file = bad_pdf
        subject.save!
      end

      it 'does not create a preview' do
        expect(subject.preview).not_to be_present
      end
    end
  end

  describe '#parent_folders' do
    let(:grandfather) { FactoryGirl.create(:document_folder) }
    let(:father) { FactoryGirl.create(:document_folder, folder_id: grandfather.id) }
    let(:son) { FactoryGirl.create(:document, :with_fake_file, folder_id: father.id) }

    it 'returns an array of all ancestors' do
      expect(son.parent_folders).to eq([father, grandfather])
    end
  end

  describe '#parent_folder_group_ids' do
    let(:group1) { FactoryGirl.create(:group) }
    let(:group2) { FactoryGirl.create(:group) }
    let(:grandfather) { FactoryGirl.create(:document_folder, group_ids: [group1.id]) }
    let(:father) { FactoryGirl.create(:document_folder, folder_id: grandfather.id, group_ids: [group1.id, group2.id]) }
    let(:son) { FactoryGirl.create(:document, :with_fake_file, folder_id: father.id) }

    it 'returns an array of all group ids' do
      expect(son.parent_folder_group_ids).to match_array([group1.id, group2.id])
    end
  end

  describe '#hidden?' do
    context 'given a parent folder is hidden' do
      let(:grandfather) { FactoryGirl.create(:document_folder, hidden: true) }
      let(:father) { FactoryGirl.create(:document_folder, folder_id: grandfather.id) }
      let(:son) { FactoryGirl.create(:document, :with_fake_file, folder_id: father.id) }

      it 'returns true' do
        expect(son.hidden?).to eq(true)
      end
    end

    context 'given no parent folders are hidden' do
      let(:grandfather) { FactoryGirl.create(:document_folder) }
      let(:father) { FactoryGirl.create(:document_folder, folder_id: grandfather.id) }
      let(:son) { FactoryGirl.create(:document, :with_fake_file, folder_id: father.id) }

      it 'returns false' do
        expect(son.hidden?).to eq(false)
      end
    end

    context 'given no parent folders' do
      let(:son) { FactoryGirl.create(:document, :with_fake_file) }

      it 'returns false' do
        expect(son.hidden?).to eq(false)
      end
    end
  end
end
