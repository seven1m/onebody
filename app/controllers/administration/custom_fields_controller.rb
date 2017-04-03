class Administration::CustomFieldsController < ApplicationController
  before_filter :only_admins

  def index
    @fields = CustomField.for_people.order(:name)
  end

  def new
    @field = CustomField.for_people.new
  end

  def create
    @field = CustomField.for_people.create(field_params)
    if @field.valid?
      redirect_to action: :index
    else
      render action: :new
    end
  end

  def edit
    @field = CustomField.for_people.find(params[:id])
  end

  def update
    @field = CustomField.for_people.find(params[:id])
    if @field.update(field_params)
      redirect_to action: :index
    else
      render action: :edit
    end
  end

  def destroy
    @field = CustomField.for_people.find(params[:id])
    @field.destroy
    redirect_to action: :index
  end

  private

  def field_params
    params.require(:custom_field).permit(:name, :format)
  end
end
