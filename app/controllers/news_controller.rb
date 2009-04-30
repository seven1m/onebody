class NewsController < ApplicationController

  def index
    @news_items = NewsItem.all(:order => 'published desc', :conditions => ['active = ?', true])
    respond_to do |format|
      format.html
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

end
