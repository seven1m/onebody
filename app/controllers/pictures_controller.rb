class PicturesController < ApplicationController
  LoadAndAuthorizeResource::METHOD_TO_ACTION_NAMES['next'] = 'read'
  LoadAndAuthorizeResource::METHOD_TO_ACTION_NAMES['prev'] = 'read'

  load_and_authorize_parent :group, optional: true, only: :create, children: :albums
  load_and_authorize_parent :album, optional: true
  before_filter :find_or_create_album_by_name, only: :create
  load_and_authorize_resource except: %i(index new create)

  def index
    redirect_to @album
  end

  def show
  end

  def new
    @albums = @logged_in.albums.order(:name)
    if @albums.size == 0
      flash[:notice] = t('pictures.create_an_album.notice')
      redirect_to new_person_album_path(@logged_in)
    end
  end

  def next
    redirect_to [@album, @picture.next]
  end

  def prev
    redirect_to [@album, @picture.prev]
  end

  def create
    @uploader = PictureUploader.new(@album, params, current_user)
    if @uploader.save
      flash[:notice] = t('pictures.saved', success: @uploader.success)
      respond_to do |format|
        format.html { redirect_to @album }
        format.json { render json: { status: 'success', url: album_path(@album) } }
      end
    else
      respond_to do |format|
        format.html do
          flash[:error] = @uploader.errors.values.join('; ')
          render action: 'new'
        end
        format.json { render json: { status: 'error', errors: @uploader.errors.values } }
      end
    end
  end

  # rotate / cover selection
  def update
    if params[:degrees]
      @picture.rotate params[:degrees].to_i
      redirect_to [@album, @picture]
    elsif params[:cover]
      @album.update_attributes!(cover: @picture)
      redirect_to @album
    end
  end

  def destroy
    @picture.destroy
    redirect_to @album
  end

  private

  def find_or_create_album_by_name
    return if @album
    return unless params[:album].presence
    @album = albums.where(name: params[:album].presence).first_or_create! do |album|
      album.owner ||= current_user
      Authority.enforce(:create, album, current_user)
    end
  end
end
