class DirectoryMapsController < ApplicationController
  def index
  end

  def family_locations
    mapable_families = Family.all.select(&:mapable?)
    map_view_details = []
    mapable_families.each do |family|
      map_view_details << family.attributes.select do |key, _value|
        ['longitude', 'latitude', 'name', 'id'].include?(key)
      end
    end
    respond_to do |format|
      format.json { render json: map_view_details }
    end
  end
end
