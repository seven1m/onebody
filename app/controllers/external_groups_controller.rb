class ExternalGroupsController < ApplicationController
  
  before_filter :only_if_can_export
  
  def index
    @external_groups = ExternalGroup.all(:order => 'name')
    respond_to do |format|
      format.xml  { render :xml => @external_groups }
      format.json { render :text => @external_groups.to_json }
    end
  end
  
  def show
    @external_group = params[:external_id] ? ExternalGroup.find_by_external_id(params[:id]) : ExternalGroup.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @external_group
    respond_to do |format|
      format.xml  { render :xml => @external_group }
      format.json { render :text => @external_group.to_json }
    end
  end
  
  def create
    @external_group = ExternalGroup.new(params[:external_group])
    respond_to do |format|
      if @external_group.save
        format.xml { render :xml => @external_group, :status => :created, :location => @external_group }
      else
        format.xml { render :xml => @external_group.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def update
    @external_group = ExternalGroup.find(params[:id])
    respond_to do |format|
      if @external_group.update_attributes(params[:external_group])
        format.xml { head :ok }
      else
        format.xml { render :xml => @external_group.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @external_group = ExternalGroup.find(params[:id])
    @external_group.destroy
    respond_to do |format|
      format.xml { head :ok }
    end
  end
  
  private
  
    def only_if_can_export
      unless can_export?
        render :text => 'You are unauthorized.', :status => 401
        return false
      end
    end
  
end
