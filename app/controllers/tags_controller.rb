class TagsController < ApplicationController

  def show
    @tag = params[:id].to_s =~ /^\d+$/ ? Tag.find(params[:id]) : Tag.find_by_name(params[:id])
  end

end
