class NewsController < ApplicationController

  def index
    @news_items = NewsItem.find_all_by_active(true, :order => 'published desc', :include => :person)
    respond_to do |format|
      format.html do
        unless Setting.get(:features, :news_page)
          if the_url = Setting.get(:url, :news)
            redirect_to the_url
          else
            render :text => 'This feature is currently unavailable.'
          end
        end
      end
      format.js do
        if @news_items.any?
          @headlines = @news_items.map do |item|
            [item.title, item.link]
          end
          render :layout => false
        else
          render :text => ''
        end
      end
    end
  end

  def show
    if Setting.get(:features, :news_page)
      respond_to do |format|
        format.html do
          @news_item = NewsItem.find(params[:id])
        end
      end
    else
      respond_to do |format|
        format.html do
          if the_url = Setting.get(:url, :news)
            redirect_to the_url
          else
            render :text => 'This feature is currently unavailable.'
          end
        end
      end
    end
  end

  def new
    if @logged_in.admin?(:manage_news) or Setting.get(:features, :news_by_users)
      @news_item = NewsItem.new
    else
      render :text => 'You cannot add news here.', :layout => true, :status => 401
    end
  end

  def create
    @news_item = NewsItem.new(params[:news_item])
    if @news_item.save
      respond_to do |format|
        format.html { flash[:notice] = 'News saved.'; redirect_to @news_item }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' } 
      end
    end
  end

  def edit
    @news_item = NewsItem.find(params[:id])
    unless @logged_in.admin?(:manage_news) or (Setting.get(:features, :news_by_users) and @news_item.person == @logged_in)
      render :text => 'You cannot edit this news item.', :layout => true, :status => 401
    end
  end

  def update
    @news_item = NewsItem.find(params[:id])
    if @logged_in.admin?(:manage_news) or (Setting.get(:features, :news_by_users) and @news_item.person == @logged_in)
      if @news_item.update_attributes(params[:news_item])
        respond_to do |format|
          format.html { flash[:notice] = 'News saved.'; redirect_to @news_item }
        end
      else
        respond_to do |format|
          format.html { render :action => 'edit' } 
        end
      end
    else
      render :text => 'You cannot edit this news item.', :layout => true, :status => 401
    end
  end

  def destroy
    @news_item = NewsItem.find(params[:id])
    if @logged_in.admin?(:manage_news) or (Setting.get(:features, :news_by_users) and @news_item.person == @logged_in)
      @news_item.destroy
      respond_to do |format|
        format.html { flash[:notice] = 'News deleted.'; redirect_to news_items_path }
      end
    else
      render :text => 'You cannot delete this news item.', :layout => true, :status => 401
    end
  end
  
  def create
    @news_item = NewsItem.new(params[:news_item])
    if @news_item.save
      flash[:notice] = 'Your news has been submitted.'
      redirect_to news_path
    else
      render :action => 'new'
    end
  end
end
