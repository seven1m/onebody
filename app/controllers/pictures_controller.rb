class PicturesController < ApplicationController

  LoadAndAuthorizeResource::METHOD_TO_ACTION_NAMES.merge!(
    'next' => 'rotate',
    'prev' => 'rotate',
  )

  load_and_authorize_parent :group, optional: true, only: :create, children: :albums
  load_and_authorize_parent :album, optional: true
  before_filter :find_or_create_album_by_name, only: :create
  load_and_authorize_resource except: [:index, :create]

  def index
    @pictures = pictures.order(:id).page(params[:page])
  end

  def show
  end

  def next
    redirect_to [@album, @picture.next]
  end

  def prev
    redirect_to [@album, @picture.prev]
  end

  def create
    @uploader = PictureUploader.new(@album, params, current_user)
    @uploader.save
    notices = [t('pictures.saved', success: @uploader.success)]
    notices << t('pictures.failed', fail: @uploader.fail) if @uploader.fail > 0
    flash[:notice] = notices.join('<br/>')
    redirect_to params[:redirect_to] || @group || album_pictures_path(@album)
  end

  # rotate / cover selection
  def update
    if params[:degrees]
      @picture.rotate params[:degrees].to_i
    elsif params[:cover]
      @album.update_attributes!(cover: @picture)
    end
    redirect_to [@album, @picture]
  end

  def destroy
    @picture.destroy
    redirect_to @album
  end

  private

  def find_or_create_album_by_name
    return if @album or not params[:album]
    unless @album = albums.where(name: params[:album]).first
      @album = albums.new(name: params[:album])
      Authority.enforce(:create, @album, current_user)
      @album.save!
    end
    @album.owner ||= @logged_in # if not owned by group
  end

end
