class StreamsController < ApplicationController

  def show
    @stream_items = @logged_in.stream_items(30)
  end

end
