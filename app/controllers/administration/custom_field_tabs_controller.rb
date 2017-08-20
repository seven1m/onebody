class Administration::CustomFieldTabsController < ApplicationController
  before_filter :only_admins

  def new
    @tab = CustomFieldTab.new
  end

  def create
    @tab = CustomFieldTab.create(tab_params)
    if @tab.valid?
      redirect_to administration_custom_fields_path
    else
      render action: :new
    end
  end

  def edit
    @tab = CustomFieldTab.find(params[:id])
  end

  def update
    @tab = CustomFieldTab.find(params[:id])
    if @tab.update(tab_params)
      redirect_to administration_custom_fields_path
    else
      render action: :edit
    end
  end

  def destroy
    @tab = CustomFieldTab.find(params[:id])
    if @tab.fields.none?
      @tab.destroy
      redirect_to administration_custom_fields_path
    else
      redirect_to edit_administration_custom_field_tab_path(@tab),
                  flash: { warning: t('admin.custom_field_tabs.delete.disabled') }
    end
  end

  def update_position
    @field = CustomField.find(params[:id])
    @field.insert_at(params[:position].to_i)
    render nothing: true
  end

  private

  def tab_params
    params.require(:custom_field_tab).permit(:name)
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
