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

end
