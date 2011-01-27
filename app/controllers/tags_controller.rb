class TagsController < ApplicationController

  def show
    unless @tag = params[:id].to_s =~ /^\d+$/ ? Tag.find(params[:id]) : Tag.find_by_name(params[:id])
      raise ActiveRecord::RecordNotFound
    end
  end

end
