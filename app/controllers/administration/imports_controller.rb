class Administration::ImportsController < ApplicationController
  before_filter :only_admins

  def index
    @imports = Import.order(created_at: :desc)
  end

  def show
    @import = Import.find(params[:id])
    respond_to do |format|
      format.html do
        redirect_to(action: :edit) if @import.parsed?
      end
      format.json do
        render json: @import
      end
    end
  end

  def new
  end

  def create
    return redirect_to(action: 'new') unless params[:file]
    @import = Import.create(
      person:          @logged_in,
      filename:        params[:file].original_filename,
      importable_type: 'Person',
      status:          'pending'
    )
    @import.parse_async(
      file:          params[:file],
      strategy_name: 'csv'
    )
    redirect_to administration_import_path(@import)
  end

  def edit
    @import = Import.find(params[:id])
    @import.update_attributes(status: 'parsed', match_strategy: nil)
    @example = build_example
  end

  def update
    @import = Import.find(params[:id])
    @import.attributes = import_params
    @import.mappings = params[:import][:mappings]
    @import.status = 'matched' if params[:status] == 'matched'
    if @import.save
      redirect_to administration_import_path(@import)
    else
      @example = build_example
      render action :edit
    end
  end

  def destroy
    @import = Import.find(params[:id])
    @import.destroy
    redirect_to administration_imports_path
  end

  private

  def import_params
    params.require(:import).permit(:match_strategy)
  end

  def build_example
    @import.rows.first.try(:import_attributes_as_hash) || {}
  end

  def only_admins
    return if @logged_in.admin?(:import_data)
    render text: t('only_admins'), layout: true, status: 401
    false
  end
end
