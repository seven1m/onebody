class StreamsController < ApplicationController
  skip_before_filter :authenticate_user, only: %w(show)
  before_filter :authenticate_user_with_code_or_session, only: %w(show)

  include TimelineHelper

  def show
    unless @logged_in.active?
      redirect_to(@logged_in)
      return
    end
    unless Setting.get(:features, :stream)
      redirect_to('/search')
      return
    end
    if params[:stream_item_group_id]
      @stream_group = StreamItem.where(streamable_type: 'StreamItemGroup').find(params[:stream_item_group_id])
      @stream_items = @stream_group.items
    elsif params[:group_id]
      @group = Group.find(params[:group_id])
      @stream_items = @logged_in.can_read?(@group) ? @group.stream_items : @group.stream_items.none
    else
      @stream_items = StreamItem.shared_with(@logged_in)
      @stream_items.where!(person_id: params[:person_id]) if params[:person_id]
    end
    @count = @stream_items.count
    @stream_items = @stream_items.paginate(page: params[:timeline_page], per_page: params[:per_page] || 5)
    record_last_seen_stream_item
    respond_to do |format|
      format.html
      format.xml { render layout: false }
      format.json do
        render json: {
          html: html_for_json,
          items: @stream_items,
          count: @count,
          next: timeline_has_more?(@stream_items) ? next_timeline_url(@stream_items.current_page + 1) : nil
        }
      end
    end
  end

  private

  def html_for_json
    if @stream_group
      @stream_items.map { |si| si.decorate.to_html }.join
    else
      view_context.timeline(@stream_items)
    end
  end

  def record_last_seen_stream_item
    was = @logged_in.last_seen_stream_item
    @logged_in.record_last_seen_stream_item(@stream_items.first)
    @logged_in.last_seen_stream_item = was # so the "new" labels show in the view
  end
end
