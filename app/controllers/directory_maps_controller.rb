class DirectoryMapsController < ApplicationController
  def index
  end

  def family_locations
    render json: Family.mappable_details
  end
end
