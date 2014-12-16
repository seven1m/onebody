require_relative '../rails_helper'

describe Picture do

  before do
    @picture = FactoryGirl.create(:picture, :with_file)
  end

  it 'should rotate' do
    before = File.read(@picture.photo.path)
    expect(@picture.rotate(90)).to be
    after = File.read(@picture.photo.path)
    expect(before != after).to be
  end

  context '#next' do
    before do
      @album = FactoryGirl.create(:album)
      @pictures = FactoryGirl.create_list(:picture, 2, album: @album)
    end

    context 'given a picture in the album' do
      before do
        @result = @pictures.first.next
      end

      it 'should return next picture' do
        expect(@result).to eq(@pictures.second)
      end
    end

    context 'given the last picture in the album' do
      before do
        @result = @pictures.last.next
      end

      it 'should return the first picture' do
        expect(@result).to eq(@pictures.first)
      end
    end
  end

  context '#prev' do
    before do
      @album = FactoryGirl.create(:album)
      @pictures = FactoryGirl.create_list(:picture, 2, album: @album)
    end

    context 'given a picture in the album' do
      before do
        @result = @pictures.second.prev
      end

      it 'should return previous picture' do
        expect(@result).to eq(@pictures.first)
      end
    end

    context 'given the first picture in the album' do
      before do
        @result = @pictures.first.prev
      end

      it 'should return the last picture' do
        expect(@result).to eq(@pictures.last)
      end
    end
  end

end
