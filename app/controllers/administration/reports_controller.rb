class Administration::ReportsController < ApplicationController

  before_filter :only_admins_can_run_reports,    :only => ['index', 'show']
  before_filter :only_admins_can_manage_reports, :only => ['new', 'create', 'edit', 'update', 'destroy']
  
  def index
    if @logged_in.super_admin?
      @reports = Report.all(:order => 'name')
    else
      @reports = @logged_in.admin.all_reports
    end
    @offline = true unless Report.db
  end
  
  def show
    if Report.db
      @report = Report.find(params[:id])
      if @report.runnable_by?(@logged_in)
        begin
          @results = @report.run
        rescue Mongo::OperationFailure => e
          render :text => "#{I18n.t('reporting.error_running_report')}<br/><br/><pre>#{e.message rescue 'none given'}</pre>", :layout => true
        rescue Mongo::ConnectionFailure => e
          render :text => "#{I18n.t('reporting.report_database_offline')}<br/><br/><pre>#{e.message rescue 'none given'}</pre>", :layout => true
        end
      else
        render :text => I18n.t(:only_admins), :layout => true, :status => 401
      end
    else
      render :text => I18n.t('reporting.report_database_offline'), :layout => true, :status => 500
    end
  end
  
  def new
    @report = Report.new(Report::DEFAULT_DEFINITION)
    @conditions = @report.selector_for_form
    @admins = Admin.all_for_presentation
  end
  
  def create
    params[:report].reverse_merge!(Report::DEFAULT_DEFINITION)
    if params[:add]
      Report.add_condition_to_params!(params[:report][:selector], params[:add].to_i)
    elsif params[:remove]
      Report.remove_condition_from_params!(params[:report][:selector], params[:remove].to_i)
    elsif params[:addgroup]
      Report.add_group_to_params!(params[:report][:selector], params[:addgroup].to_i)
    elsif params[:move]
      Report.move_condition_in_params!(params[:report][:selector], params[:move].to_i, params[:direction])
    elsif params[:flip]
      Report.flip_conjunctions_in_params!(params[:report][:selector])
    end
    @report = Report.new(params[:report])
    @report.created_by = @logged_in
    if params[:preview]
      @conditions = @report.selector_for_form
    elsif @report.save
      redirect_to params[:continue_editing] ? edit_administration_report_path(@report) : administration_report_path(@report)
    else
      @conditions = @report.selector_for_form
      @admins = Admin.all_for_presentation
      render :action => 'new'
    end
  end
  
  def edit
    @report = Report.find(params[:id])
    @conditions = @report.selector_for_form
    @admins = Admin.all_for_presentation
  end
  
  def update
    @report = Report.find(params[:id])
    @report.attributes = params[:report]
    @conditions = @report.selector_for_form
    if @report.save
      redirect_to params[:continue_editing] ? edit_administration_report_path(@report) : administration_report_path(@report)
    else
      @admins = Admin.all_for_presentation
      render :action => 'edit'
    end
  end
  
  def destroy
    @report = Report.find(params[:id])
    @report.destroy
    redirect_to administration_reports_path
  end
  
  private
  
    def only_admins_can_run_reports
      unless @logged_in.admin?(:run_reports)
        render :text => I18n.t('only_admins'), :layout => true, :status => 401
        return false
      end
    end
    
    def only_admins_can_manage_reports
      unless @logged_in.admin?(:manage_reports)
        render :text => I18n.t('only_admins'), :layout => true, :status => 401
        return false
      end
    end
    
end
