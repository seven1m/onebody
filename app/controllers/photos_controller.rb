class PhotosController < ApplicationController

  skip_before_filter :authenticate_user, :only => %w(show tn small medium large)
  before_filter :authenticate_user_with_code_or_session, :only => %w(show tn small medium large)

  cache_sweeper :person_sweeper, :family_sweeper, :only => %w(update destroy)

  PHOTO_TYPES = %w(Family Person Recipe Picture Group) # be sure to add tests to photos_controller_test

  before_filter :get_object

  def show
    if @logged_in.can_see?(@object)
      send_photo(@object)
    else
      render :text => t('photos.unavailable'), :status => 404
    end
  end

  def tn;     params[:size] = 'tn';     show; end
  def small;  params[:size] = 'small';  show; end
  def medium; params[:size] = 'medium'; show; end
  def large;  params[:size] = 'large';  show; end

  def update
    if @logged_in.can_edit?(@object)
      if params[:photo_url] and params[:photo_url].length > 7
        @object.photo = params[:photo_url]
      elsif params[:photo]
        @object.photo = params[:photo]
      end
      redirect_back
    else
      render :text => t('photos.unavailable'), :status => 500
    end
  end

  def destroy
    if @logged_in.can_edit?(@object)
      @object.photo = nil
      redirect_back
    else
      render :text => t('photos.unavailable'), :status => 500
    end
  end

  private

  def get_object
    # /families/123/photo
    # /families/123/photo/large
    if id_key = params.keys.select { |k| k =~ /_id$/ }.last \
      and PHOTO_TYPES.include?(@type = id_key.split('_').first.classify)
      @object = Kernel.const_get(@type).find(params[id_key])
    else
      render :text => t('photos.object_not_found'), :layout => true, :status => 404
      return false
    end
  end

end
