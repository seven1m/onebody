class StreamsController < ApplicationController

  skip_before_filter :authenticate_user, :only => %w(show)
  before_filter :authenticate_user_with_code_or_session, :only => %w(show)

  def show
    unless fragment_exist?(:controller => 'streams', :action => 'show', :for => @logged_in.id, :fragment => 'stream_items')
      @stream_items = @logged_in.shared_stream_items(30)
    end
    @person = @logged_in
    unless fragment_exist?(:controller => 'streams', :action => 'show', :for => @logged_in.id, :fragment => 'friendship_requests')
      @has_friendship_requests = @logged_in.pending_friendship_requests.count > 0
    end
    @album_names = @person.albums.all(:select => 'name').map { |a| a.name }
    respond_to do |format|
      format.html
      format.xml { render :layout => false }
    end
  end

end
