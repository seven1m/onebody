class NewsController < ApplicationController
  def index
    @news_items = NewsItem.find :all, :order => 'published desc'
  end
  
  def view
    @news_item = NewsItem.find params[:id]
  end
  
  def marquee
    if (items = NewsItem.find :all, :order => 'published desc').any?
      @headlines = items.map do |item|
        [item.title, item.link]
      end
      render_without_layout
    else
      render :text => ''
    end
  end
end
