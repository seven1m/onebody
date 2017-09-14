require 'rails_helper'

describe Picture, type: :model do
  describe '#rotate' do
    let(:picture) { FactoryGirl.create(:picture, :with_file) }

    it 'should rotate' do
      before = File.read(picture.photo.path)
      expect(picture.rotate(90)).to be
      after = File.read(picture.photo.path)
      expect(before != after).to be
    end
  end

  describe '#next' do
    let(:album)    { FactoryGirl.create(:album) }
    let(:pictures) { FactoryGirl.create_list(:picture, 2, album: album) }

    context 'given a picture in the album' do
      before do
        @result = pictures.first.next
      end

      it 'should return next picture' do
        expect(@result).to eq(pictures.second)
      end
    end

    context 'given the last picture in the album' do
      before do
        @result = pictures.last.next
      end

      it 'should return the first picture' do
        expect(@result).to eq(pictures.first)
      end
    end
  end

  describe '#prev' do
    let(:album)    { FactoryGirl.create(:album) }
    let(:pictures) { FactoryGirl.create_list(:picture, 2, album: album) }

    context 'given a picture in the album' do
      before do
        @result = pictures.second.prev
      end

      it 'should return previous picture' do
        expect(@result).to eq(pictures.first)
      end
    end

    context 'given the first picture in the album' do
      before do
        @result = pictures.first.prev
      end

      it 'should return the last picture' do
        expect(@result).to eq(pictures.last)
      end
    end
  end

  describe '#create_as_stream_item' do
    context 'given a new Picture in a public album' do
      let!(:user)    { FactoryGirl.create(:person) }
      let!(:album)   { FactoryGirl.create(:album, is_public: true) }
      let!(:picture) { FactoryGirl.create(:picture, album: album, person: user) }

      it 'creates a stream item' do
        expect(album.reload.stream_item.attributes).to include(
          'title'     => album.name,
          'is_public' => true
        )
      end
    end
  end
end
