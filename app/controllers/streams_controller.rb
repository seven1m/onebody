class StreamsController < ApplicationController

  skip_before_filter :authenticate_user, only: %w(show)
  before_filter :authenticate_user_with_code_or_session, only: %w(show)

  include TimelineHelper

  def show
    redirect_to(@logged_in) and return unless @logged_in.full_access?
    if params[:group_id]
      @group = Group.find(params[:group_id])
      @stream_items = @logged_in.can_read?(@group) ? @group.stream_items : @group.stream_items.none
    else
      @stream_items = StreamItem.shared_with(@logged_in)
      @stream_items.where!(person_id: params[:person_id]) if params[:person_id]
    end
    @count = @stream_items.count
    @stream_items = @stream_items.paginate(page: params[:timeline_page], per_page: params[:per_page] || 5)
    respond_to do |format|
      format.html
      format.xml { render layout: false }
      format.json do
        render json: {
          html: view_context.timeline(@stream_items),
          items: @stream_items,
          count: @count,
          next: timeline_has_more?(@stream_items) ? next_timeline_url(@stream_items.current_page + 1) : nil
        }
      end
    end
  end

end
