class SharesController < ApplicationController
  
  def index
    @publications = Publication.all(:order => 'created_at desc')
  end
  
end
