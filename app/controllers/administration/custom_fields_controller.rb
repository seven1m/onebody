class Administration::CustomFieldsController < ApplicationController
  before_filter :only_admins

  def index
    @fields = CustomField.order(:position)
  end

  def new
    @field = CustomField.new
  end

  def create
    @field = CustomField.create(field_params_massaged)
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
    if @field.update(field_params_massaged)
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

  def update_position
    @field = CustomField.find(params[:id])
    @field.insert_at(params[:position].to_i)
    render nothing: true
  end

  private

  def field_params
    params.require(:custom_field).permit(
      :name,
      :format,
      custom_field_options_attributes: %i(id label _destroy)
    )
  end

  def field_params_massaged
    return field_params unless field_params[:custom_field_options_attributes]
    field_params.tap do |p|
      p[:custom_field_options_attributes].each_with_index do |option, index|
        option[:id] = nil if option[:id].start_with?('new')
        option[:sequence] = index + 1
      end
    end
  end
end
