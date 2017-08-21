class Administration::Checkin::CardsController < ApplicationController
  before_filter :only_admins

  VALID_SORT_COLS = ['id', 'legacy_id', 'last_name,name', 'barcode_id', 'barcode_assigned_at desc'].freeze

  def index
    respond_to do |format|
      scope = Family.where("barcode_id is not null and barcode_id != '' and deleted = ?", false)
      format.html do
        params[:sort] = 'barcode_assigned_at desc' unless VALID_SORT_COLS.include?(params[:sort])
        @families = scope.order(params[:sort]).paginate(per_page: 100, page: params[:page])
      end
      format.csv do
        @families = scope.select('id, legacy_id, name, last_name, barcode_id, barcode_assigned_at')
                         .order('barcode_assigned_at desc')
        out = CSV.generate do |csv|
          @families.each do |family|
            csv << [family.id, family.legacy_id, family.name, family.barcode_id, family.barcode_assigned_at]
          end
        end
        render plain: out
      end
    end
  end

  private

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
