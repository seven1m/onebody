class StreamsController < ApplicationController

  def show
    @stream_items = StreamItem.all(:order => 'created_at desc', :limit => 100)
  end

end
