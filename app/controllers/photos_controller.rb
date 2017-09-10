class PhotosController < ApplicationController
  PHOTO_TYPES = {
    'family_id'  => Family,
    'person_id'  => Person,
    'picture_id' => Picture,
    'group_id'   => Group
  }.freeze

  before_action :get_object

  def update
    if @logged_in.can_update?(@object)
      if params[:photo]
        @object.photo = params[:photo]
        # annoying to users if changing their photo fails due to some other unrelated validation failure
        # this is a total hack
        if @object.valid? || (errors = @object.errors.select { |a, _e| a.to_s =~ /^photo/ }).empty?
          @object.save(validate: false)
          if @id_key == 'family_id' || @id_key == 'person_id'
            Notifier.photo_update(@object, @id_key == 'family_id') if Setting.get(:features, :notify_on_photo_change)
          end
        else
          @errors = errors
        end
      end
      respond_to do |format|
        format.html do
          flash[:warning] = @errors.map(&:last).join("\n") if @errors
          redirect_back
        end
        format.json do
          if @errors
            render json: { status: :error, errors: @errors.map(&:last).uniq }
          else
            urls = @object.photo.styles.each_with_object({}) do |(k, _), h|
              h[k] = @object.photo.url(k)
            end
            render json: { status: :success, photo: urls }
          end
        end
      end
    else
      render plain: t('photos.unavailable'), status: 500
    end
  end

  def destroy
    if @logged_in.can_update?(@object)
      @object.photo = nil
      @object.save(validate: false)
      respond_to do |format|
        format.html { redirect_back }
        format.json
      end
    else
      render plain: t('photos.unavailable'), status: 500
    end
  end

  private

  def get_object
    # /families/123/photo
    # /families/123/photo/large
    if (id_key = params.keys.select { |k| k =~ /_id$/ }.last) && (model = PHOTO_TYPES[id_key])
      @id_key = id_key
      @object = model.find(params[id_key])
    else
      render html: t('photos.object_not_found'), layout: true, status: 404
      false
    end
  end
end
