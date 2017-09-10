class NewsController < ApplicationController
  skip_before_action :authenticate_user, only: %w(index)
  before_action :authenticate_user_with_code_or_session, only: %w(index)

  def index
    respond_to do |format|
      format.html do
        if Setting.get(:features, :news_page)
          @news_items = NewsItem.active.order('published desc').includes(:person).page(params[:page])
        else
          if the_url = Setting.get(:url, :news)
            redirect_to the_url
          else
            render plain: t('feature_unavailable')
          end
        end
      end
      format.xml do
        if Setting.get(:features, :news_page)
          @news_items = NewsItem.where(active: true).includes(:person).limit(30).order('published desc')
          render layout: false
        else
          if the_url = Setting.get(:url, :news)
            redirect_to the_url
          else
            render plain: t('feature_unavailable')
          end
        end
      end
    end
  end

  def show
    if Setting.get(:features, :news_page)
      @news_item = NewsItem.find(params[:id])
      respond_to do |format|
        format.html
      end
    else
      respond_to do |format|
        format.html do
          if the_url = Setting.get(:url, :news)
            redirect_to the_url
          else
            render plain: t('feature_unavailable')
          end
        end
      end
    end
  end

  def new
    if @logged_in.admin?(:manage_news) || Setting.get(:features, :news_by_users)
      @news_item = NewsItem.new
    else
      render html: t('not_authorized'), layout: true, status: 401
    end
  end

  def create
    if @logged_in.admin?(:manage_news) || Setting.get(:features, :news_by_users)
      @news_item = NewsItem.new(news_item_params)
      @news_item.person = @logged_in
      @news_item.source = 'user'
      if @news_item.save
        respond_to do |format|
          format.html do
            flash[:notice] = t('news.saved')
            redirect_to params[:redirect_to] || @news_item
          end
        end
      else
        respond_to do |format|
          format.html { render action: 'new' }
        end
      end
    else
      render html: t('not_authorized'), layout: true, status: 401
    end
  end

  def edit
    @news_item = NewsItem.find(params[:id])
    unless @logged_in.can_update?(@news_item)
      render html: t('not_authorized'), layout: true, status: 401
    end
  end

  def update
    @news_item = NewsItem.find(params[:id])
    if @logged_in.can_update?(@news_item)
      if @news_item.update_attributes(news_item_params)
        respond_to do |format|
          format.html { flash[:notice] = t('news.saved'); redirect_to @news_item }
        end
      else
        respond_to do |format|
          format.html { render action: 'edit' }
        end
      end
    else
      render html: t('not_authorized'), layout: true, status: 401
    end
  end

  def destroy
    @news_item = NewsItem.find(params[:id])
    if @logged_in.can_update?(@news_item)
      @news_item.destroy
      respond_to do |format|
        format.html { flash[:notice] = t('news.deleted'); redirect_to news_path }
      end
    else
      render html: t('not_authorized'), layout: true, status: 401
    end
  end

  private

  def news_item_params
    params.require(:news_item).permit(:title, :body)
  end
end
