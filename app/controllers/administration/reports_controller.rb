class Administration::ReportsController < ApplicationController

  def index
    @report_names = (Pathname.glob('app/reports/*').map{ |f| f.basename('_report.rb') }.collect(&:to_s)).sort
  end

end
