class TagsController < ApplicationController
  def view
    @tag = Tag.find_by_name(params[:id]) || Tag.find(params[:id])
  end
end
