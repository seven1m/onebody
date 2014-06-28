class Administration::Checkin::CardsController < ApplicationController

  before_filter :only_admins
  
  VALID_SORT_COLS = ['id', 'legacy_id', 'last_name,name', 'barcode_id', 'barcode_assigned_at desc']
  
  def index
    respond_to do |format|
      format.html do
        params[:sort] = 'barcode_assigned_at desc' unless VALID_SORT_COLS.include?(params[:sort])
        @families = Family.paginate(
          :conditions => ["barcode_id is not null and barcode_id != '' and deleted = ?", false],
          :order      => params[:sort],
          :page       => params[:page],
          :per_page   => 100
        )
      end
      format.csv do
        @families = Family.all(
          :select     => 'id, legacy_id, name, last_name, barcode_id, barcode_assigned_at',
          :conditions => ["barcode_id is not null and barcode_id != '' and deleted = ?", false],
          :order      => 'barcode_assigned_at desc'
        )
        out = CSV.generate do |csv|
          @families.each do |family|
            csv << [family.id, family.legacy_id, family.name, family.barcode_id, family.barcode_assigned_at]
          end
        end
        render text: out
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
      unless Setting.get(:features, :checkin)
        render :text => 'This feature is unavailable.', :layout => true
        false
      end
    end
  
end
