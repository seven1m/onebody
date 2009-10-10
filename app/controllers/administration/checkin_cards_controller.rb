class Administration::CheckinCardsController < ApplicationController

  before_filter :only_admins
  
  VALID_SORT_COLS = ['last_name,name', 'barcode_id', 'barcode_assigned_at desc']
  
  def index
    respond_to do |format|
      format.html do
        params[:sort] = 'barcode_assigned_at desc' unless VALID_SORT_COLS.include?(params[:sort])
        @families = Family.paginate(
          :conditions => "barcode_id is not null and barcode_id != ''",
          :order      => params[:sort],
          :page       => params[:page],
          :per_page   => 100
        )
      end
      format.csv do
        @families = Family.all(
          :select     => 'id, legacy_id, name, last_name, barcode_id, barcode_assigned_at',
          :conditions => "barcode_id is not null and barcode_id != ''",
          :order      => 'barcode_assigned_at desc'
        )
        render :text => @families.to_csv
      end
    end
  end
  
  private
  
    def only_admins
      unless @logged_in.admin?(:manage_checkin)
        render :text => 'You must be an administrator to use this section.', :layout => true, :status => 401
        return false
      end
    end
  
    def feature_enabled?
      unless Setting.get(:features, :checkin_modules)
        render :text => 'This feature is unavailable.', :layout => true
        false
      end
    end
  
end
