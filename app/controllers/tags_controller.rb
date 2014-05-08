class TagsController < ApplicationController

  def show
    unless @tag = params[:id].to_s =~ /^\d+$/ ? Tag.find(params[:id]) : Tag.where(name: params[:id]).first
      raise ActiveRecord::RecordNotFound
    end
  end

end
