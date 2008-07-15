class FeedsController < ApplicationController

  def show
    @person = @logged_in
    @items = @person.recently_tab_items
    @grouped_items = @items.group_by_model_name
    respond_to do |format|
      format.html # show.html.erb
      format.js { render :partial => 'feed' }
      format.rss { render :layout => false } # show.rss.builder
    end
  end

end
