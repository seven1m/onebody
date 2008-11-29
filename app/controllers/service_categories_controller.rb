class ServiceCategoriesController < ApplicationController
  def batch_edit
    @service_categories = ServiceCategory.find(:all, :order => :name)
    respond_to do |format|
      format.js
    end
  end

  def create
    @service_category = ServiceCategory.new(params[:service_category])
    if @service_category.name != "null"
      @created = @service_category.save
    end
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @service_category = ServiceCategory.find(params[:id])
    @service_category.destroy if @service_category.destroyable?
    respond_to do |format|
      format.js
    end
  end

  def update
    @service_category = ServiceCategory.find(params[:id])
    @service_category.name = params[:service_category][:name]
    if @service_category.name != "null"
      @updated = @service_category.save
    end
    respond_to do |format|
      format.js
    end
  end
end