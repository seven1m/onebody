require_relative '../test_helper'

class PictureTest < ActiveSupport::TestCase

  setup do
    @picture = FactoryGirl.create(:picture, :with_file)
  end

  should 'rotate' do
    before = File.read(@picture.photo.path)
    assert @picture.rotate(90)
    after = File.read(@picture.photo.path)
    assert before != after
  end

  context '#next' do
    setup do
      @album = FactoryGirl.create(:album)
      @pictures = FactoryGirl.create_list(:picture, 2, album: @album)
    end

    context 'given a picture in the album' do
      setup do
        @result = @pictures.first.next
      end

      should 'return next picture' do
        assert_equal @pictures.second, @result
      end
    end

    context 'given the last picture in the album' do
      setup do
        @result = @pictures.last.next
      end

      should 'return the first picture' do
        assert_equal @pictures.first, @result
      end
    end
  end

  context '#prev' do
    setup do
      @album = FactoryGirl.create(:album)
      @pictures = FactoryGirl.create_list(:picture, 2, album: @album)
    end

    context 'given a picture in the album' do
      setup do
        @result = @pictures.second.prev
      end

      should 'return previous picture' do
        assert_equal @pictures.first, @result
      end
    end

    context 'given the first picture in the album' do
      setup do
        @result = @pictures.first.prev
      end

      should 'return the last picture' do
        assert_equal @pictures.last, @result
      end
    end
  end

end
