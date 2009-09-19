class Administration::CheckinsController < ApplicationController

  before_filter :only_admins
  
  def show
    respond_to do |format|
      format.html
      format.csv do
        @families = Family.all(:select => 'id, legacy_id, name, barcode_id', :conditions => "barcode_id is not null and barcode_id != ''", :order => 'name')
        render :text => @families.to_csv
      end
    end
  end
  
end
