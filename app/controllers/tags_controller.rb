class TagsController < ApplicationController
  def show
    @tag = params[:id] =~ /^\d+$/ ? Tag.find(params[:id]) : Tag.find_by!(name: params[:id])
  end
end
