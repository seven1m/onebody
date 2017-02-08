class Administration::ReportsController < ApplicationController
  def index
    @reports = I18n.t('reports.reports')
  end
end
