class PictureUploader
  extend ActiveModel::Naming

  attr_reader :success, :fail, :errors

  def initialize(album, params, user)
    @album = album
    @params = params
    @user = user
    @success = 0
    @fail = 0
    @errors = ActiveModel::Errors.new(self)
  end

  def save
    unless @album
      @errors.add(:album, I18n.t('activerecord.errors.models.picture_uploader.attributes.album.blank'))
      return false
    end
    Array(@params[:pictures]).each do |pic|
      picture = @album.pictures.new
      Authority.enforce(:create, picture, @user)
      picture.person = @user
      picture.photo = pic
      picture.save
      if picture.photo.exists?
        @success += 1
      else
        @fail += 1
        @errors.add(:picture, pic.original_filename)
        begin
          picture.destroy # TODO: is this really needed?
        rescue
          nil
        end
      end
    end
    @fail == 0
  end

  def read_attribute_for_validation(attr)
    instance_variable_get("@#{attr}".to_sym)
  end

  def self.human_attribute_name(attr, _options = {})
    attr
  end

  def self.lookup_ancestors
    [self]
  end
end
