require_relative '../rails_helper'

describe Album do
  before do
    @album = FactoryGirl.create(:album)
  end

  context '#name' do
    context 'album name is empty' do
      before do
        @album.name = nil
      end

      it 'should be invalid' do
        expect(@album).to be_invalid
      end
    end
  end

  context '#owner' do
    context 'album owner is empty' do
      before do
        @album.owner = nil
      end

      it 'should be invalid' do
        expect(@album).to be_invalid
      end
    end
  end

  context '#cover' do
    context 'album has a picture marked as cover' do
      before do
        @other = @album.pictures.create!
        @cover = @album.pictures.create!(cover: true)
      end

      it 'should returns the picture marked cover' do
        expect(@album.cover).to eq(@cover)
      end
    end

    context 'album has no pictures marked as cover' do
      before do
        @first = @album.pictures.create!
        @second = @album.pictures.create!
      end

      it 'should returns the first picture ordered by creation' do
        expect(@album.cover).to eq(@first)
      end
    end

    context 'has has no pictures' do
      it 'should returns nil' do
        expect(@album.cover).to be_nil
      end
    end
  end

  context '#cover=' do
    context 'album has a picture marked as cover' do
      before do
        @pic1 = @album.pictures.create!(cover: true)
        @pic2 = @album.pictures.create!
        @album.update_attributes!(cover: @pic2)
      end

      it 'should unset existing as cover' do
        expect(@pic1.reload.cover).not_to be
      end

      it 'should set new cover' do
        expect(@pic2.reload.cover).to be
      end
    end
  end

  context '#group' do
    context 'album owner is a person' do
      before do
        @person = FactoryGirl.create(:person)
        @album.update_attributes!(owner: @person)
      end

      it 'should return nil' do
        expect(@album.group).to be_nil
      end
    end

    context 'album owner is a group' do
      before do
        @group = FactoryGirl.create(:group)
        @album.update_attributes!(owner: @group)
      end

      it 'should return the group' do
        expect(@album.group).to eq(@group)
      end
    end
  end

  context '#person' do
    context 'album owner is a person' do
      before do
        @person = FactoryGirl.create(:person)
        @album.update_attributes!(owner: @person)
      end

      it 'should return the person' do
        expect(@album.person).to eq(@person)
      end
    end

    context 'album owner is a group' do
      before do
        @group = FactoryGirl.create(:group)
        @album.update_attributes!(owner: @group)
      end

      it 'should return nil' do
        expect(@album.person).to be_nil
      end
    end
  end

  context '#update_stream_item' do
    context 'when the album is changed from private to public' do
      let!(:user)    { FactoryGirl.create(:person) }
      let!(:album)   { FactoryGirl.create(:album, is_public: true) }
      let!(:picture) { FactoryGirl.create(:picture, album: album, person: user) }

      it 'updates a stream item' do
        expect do
          album.is_public = false
          album.save!
        end.to change(album.stream_item.reload, :is_public?).from(true).to(false)
      end
    end
  end

  describe 'callbacks' do
    context 'when the album is destroyed' do
      let!(:album) { FactoryGirl.create(:album, is_public: true) }
      let!(:stream_item) { album.create_stream_item! }

      it 'deletes the stream item' do
        album.destroy
        expect { stream_item.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
