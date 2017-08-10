class Administration::CustomFieldsController < ApplicationController
  before_filter :only_admins

  def index
    @fields = CustomField.order(:name)
  end

  def new
    @field = CustomField.new
  end

  def create
    @field = CustomField.create(field_params)
    if @field.valid?
      redirect_to action: :index
    else
      render action: :new
    end
  end

  def edit
    @field = CustomField.find(params[:id])
  end

  def update
    @field = CustomField.find(params[:id])
    if @field.update(field_params)
      redirect_to action: :index
    else
      render action: :edit
    end
  end

  def destroy
    @field = CustomField.find(params[:id])
    @field.destroy
    redirect_to action: :index
  end

  private

  def field_params
    params.require(:custom_field).permit(
      :name,
      :format,
      custom_field_options_attributes: %i(id label _destroy)
    )
  end
end
