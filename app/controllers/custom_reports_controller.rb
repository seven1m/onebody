class CustomReportsController < ApplicationController
  before_action :set_custom_report, only: [:show, :edit, :update, :destroy]

  def index
    redirect_to admin_reports_url
  end

  def show
    if @logged_in.can_read?(@custom_report)
      @header = @custom_report.header
      @footer = @custom_report.footer
      @report_data = @custom_report.data_set(@custom_report.category)
    end
  end

  def new
    @custom_report = CustomReport.new

    if @logged_in.can_create?(@custom_report)
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  def create
    @custom_report = CustomReport.new(custom_report_params)
    if @logged_in.can_create?(@custom_report)
      if @custom_report.save
        redirect_to admin_reports_path,
                    notice: t('reports.custom_reports.create.notice')
      else
        render :new
      end
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  def edit
    unless @logged_in.can_edit?(@custom_report)
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  def update
    if @logged_in.can_edit?(@custom_report)
      if @custom_report.update(custom_report_params)
        redirect_to admin_reports_path,
                    notice: t('reports.custom_reports.update.notice')
      else
        render :edit
      end
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  def destroy
    if @logged_in.can_delete?(@custom_report)
      @custom_report.destroy
      redirect_to admin_reports_url,
                  notice: t('reports.custom_reports.destroy.notice')
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  private

  def set_custom_report
    @custom_report = CustomReport.find(params[:id])
  end

  def custom_report_params
    params.require(:custom_report)
      .permit(:title, :category, :header, :body, :footer, :filters)
  end
end
