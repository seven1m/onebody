class Administration::Checkin::LabelsController < ApplicationController
  before_action :only_admins

  def index
    @labels = CheckinLabel.order(:name)
  end

  def new
    @label = CheckinLabel.new
  end

  def edit
    @label = CheckinLabel.find(params[:id])
  end

  def create
    @label = CheckinLabel.new(label_params)
    if @label.save
      redirect_to administration_checkin_labels_path, notice: t('changes_saved')
    else
      render action: 'new'
    end
  end

  def update
    @label = CheckinLabel.find(params[:id])
    if @label.update_attributes(label_params)
      redirect_to administration_checkin_labels_path, notice: t('changes_saved')
    else
      render action: 'edit'
    end
  end

  def destroy
    CheckinLabel.find(params[:id]).destroy
    redirect_to administration_checkin_labels_path, notice: t('checkin.labels.delete.notice')
  end

  private

  def label_params
    params.require(:checkin_label).permit(:name, :description, :xml, :xml_file)
  end

  def only_admins
    unless @logged_in.admin?(:manage_checkin)
      render plain: 'You must be an administrator to use this section.', layout: true, status: 401
      false
    end
  end

  def feature_enabled?
    unless Setting.get(:features, :checkin)
      render plain: 'This feature is unavailable.', layout: true
      false
    end
  end
end
