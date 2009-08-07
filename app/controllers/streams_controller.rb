class StreamsController < ApplicationController

  skip_before_filter :authenticate_user, :only => %w(show)
  before_filter :authenticate_user_with_code_or_session, :only => %w(show)

  def show
    @stream_items = @logged_in.shared_stream_items(30)
    @person = @logged_in
    respond_to do |format|
      format.html
      format.xml { render :layout => false }
    end
  end

end
