require_relative '../rails_helper'

describe Document do

  let(:pdf) { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/attachment.pdf'), 'application/pdf', true) }
  let(:jpg) { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.jpg'), 'image/jpg', true) }

  describe '#image?' do
    context 'given a JPG image' do
      let(:document) do
        FactoryGirl.create(:document).tap do |doc|
          doc.file = jpg
          doc.save
        end
      end

      it 'returns true' do
        expect(document).to be_image
      end
    end

    context 'given a PDF image' do
      let(:document) do
        FactoryGirl.create(:document).tap do |doc|
          doc.file = pdf
          doc.save
        end
      end

      it 'returns false' do
        expect(document).to_not be_image
      end
    end
  end

  describe '#parent_folders' do
    let(:grandfather) { FactoryGirl.create(:document_folder) }
    let(:father) { FactoryGirl.create(:document_folder, folder_id: grandfather.id) }
    let(:son) { FactoryGirl.create(:document, folder_id: father.id) }

    it 'returns an array of all ancestors' do
      expect(son.parent_folders).to eq([father, grandfather])
    end
  end

  describe '#hidden?' do
    context 'given a parent folder is hidden' do
      let(:grandfather) { FactoryGirl.create(:document_folder, hidden: true) }
      let(:father) { FactoryGirl.create(:document_folder, folder_id: grandfather.id) }
      let(:son) { FactoryGirl.create(:document, folder_id: father.id) }

      it 'returns true' do
        expect(son.hidden?).to eq(true)
      end
    end

    context 'given no parent folders are hidden' do
      let(:grandfather) { FactoryGirl.create(:document_folder) }
      let(:father) { FactoryGirl.create(:document_folder, folder_id: grandfather.id) }
      let(:son) { FactoryGirl.create(:document, folder_id: father.id) }

      it 'returns false' do
        expect(son.hidden?).to eq(false)
      end
    end

    context 'given no parent folders' do
      let(:son) { FactoryGirl.create(:document) }

      it 'returns false' do
        expect(son.hidden?).to eq(false)
      end
    end
  end
end
