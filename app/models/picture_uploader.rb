class PictureUploader

  attr_reader :success, :fail

  def initialize(album, params, user)
    @album = album
    @params = params
    @user = user
    @success = 0
    @fail = 0
  end

  def save
    Array(@params[:pictures]).each do |pic|
      picture = @album.pictures.new
      Authority.enforce(:create, picture, @user)
      picture.person = @user unless @params[:remove_owner]
      picture.photo = pic
      picture.save
      if picture.photo.exists?
        @success += 1
      else
        @fail += 1
        picture.destroy rescue nil # TODO is this really needed?
      end
    end
    true
  end

end
