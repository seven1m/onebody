class NewsController < ApplicationController
  def index
    @news_items = NewsItem.find :all, :order => 'published desc', :conditions => ['active = ?', true]
  end
  
  def view
    @news_item = NewsItem.find params[:id]
  end
  
  def marquee
    if (items = NewsItem.find :all, :order => 'published desc', :conditions => ['active = ?', true]).any?
      @headlines = items.map do |item|
        #[item.title, url_for(:controller => 'news', :action => 'view', :id => item)]
        [item.title, item.link]
      end
      render_without_layout
    else
      render :text => ''
    end
  end
end
