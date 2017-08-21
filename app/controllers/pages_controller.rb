class PagesController < ApplicationController
  skip_before_filter :authenticate_user, only: %w(show_for_public)
  skip_before_filter :feature_enabled?
  before_filter :get_path
  before_filter :get_page, :get_user, only: %w(show_for_public)
  before_filter :feature_enabled?, only: %w(show_for_public) # must follow get_page

  def index
    @pages = Page.where(system: true, published: true).order(:title)
  end

  def show_for_public
    if @page
      if @page.published?
        render action: 'show', layout: 'signed_out'
      else
        render plain: t('pages.not_found'), status: 404
      end
    else
      render plain: t('pages.not_found'), status: 404
    end
  end

  def show
    @page = Page.find(params[:id])
    unless @logged_in.admin?(:edit_pages)
      redirect_to page_for_public_path(path: @page.path)
    end
  end

  def edit
    @page = Page.find(params[:id])
    unless @logged_in.can_update?(@page)
      render plain: t('not_authorized'), layout: true, status: 401
    end
  end

  def update
    @page = Page.find(params[:id])
    if @logged_in.can_update?(@page)
      if @page.update_attributes(page_params)
        flash[:notice] = t('pages.saved')
        redirect_to pages_path
      else
        render action: 'edit'
      end
    else
      render plain: t('not_authorized'), layout: true, status: 401
    end
  end

  private

  def page_params
    params.require(:page).permit(:title, :slug, :body)
  end

  def get_path
    @path = [*params[:path]].join('/')
    if @path.sub!(%r{/edit$}, '')
      redirect_to edit_page_path(Page.find(@path))
      return false
    end
  end

  def get_page
    @page = Page.find_by_id_or_path(@path)
  end

  def feature_enabled?
    unless @page && @page.system? && !@page.home?
      redirect_to stream_path
      false
    end
  end
end
