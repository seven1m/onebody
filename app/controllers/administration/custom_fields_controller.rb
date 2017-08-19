class Administration::CustomFieldsController < ApplicationController
  before_filter :only_admins

  def index
    @tabs = CustomFieldTab.order(:position).includes(:fields)
  end

  def new
    @tab = CustomFieldTab.find(params[:tab_id])
    @field = @tab.fields.new
  end

  def create
    @tab = CustomFieldTab.find(params[:tab_id])
    @field = @tab.fields.create(field_params_massaged)
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
    @field.remove_from_list
    if @field.update(field_params_massaged)
      if (old_tab_id = @field.previous_changes['tab_id'].try(:[], 0))
        @old_tab = CustomFieldTab.find(old_tab_id)
      end
      @field.insert_at(params[:custom_field][:position].to_i) if params[:custom_field][:position]
      respond_to do |format|
        format.html { redirect_to action: :index }
        format.js
      end
    else
      respond_to do |format|
        format.html { render action: :edit }
        format.js
      end
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
      :tab_id,
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
