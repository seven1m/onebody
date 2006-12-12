class TagsController < ApplicationController
  def view
    @tag = Tag.find_by_name params[:id]
  end
end
