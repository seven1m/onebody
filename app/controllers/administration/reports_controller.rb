class Administration::ReportsController < ApplicationController

  def index
    @reports = I18n.t('reports.reports')
    @custom_reports = CustomReport.order(:title)
  end

end
