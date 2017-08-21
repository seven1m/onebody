class FamiliesController < ApplicationController
  load_and_authorize_resource except: %i(show batch select)

  def index
    respond_to do |format|
      format.html { redirect_to @logged_in }
      if can_export?
        @families = Family.order('last_name, name').paginate(page: params[:page], per_page: params[:per_page] || MAX_EXPORT_AT_A_TIME)
        format.xml do
          if @families.any?
            render xml: @families.to_xml(include: [:people], except: %w(site_id))
          else
            flash[:warning] = t('No_more_records')
            redirect_to people_path
          end
        end
      end
    end
  end

  def show
    @family = if params[:legacy_id]
                Family.where(legacy_id: params[:id]).first
              elsif params[:barcode_id]
                Family.where(barcode_id: params[:id], deleted: false).first ||
                  Family.where(alternate_barcode_id: params[:id], deleted: false).first
              else
                Family.where(id: params[:id], deleted: false).first
              end
    raise ActiveRecord::RecordNotFound unless @family
    @people = @family.people.undeleted.to_a.select { |p| @logged_in.can_read?(p) }
    if @logged_in.can_read?(@family)
      respond_to do |format|
        format.html
        format.xml  { render xml: @family.to_xml } if can_export?
        format.json { render plain: @family.to_json(except: %w(site_id)) } if can_export?
        format.js do
          if params[:barcode_entry]
            render :update do |page|
              page.replace_html 'family', partial: 'details'
              page.replace_html 'barcode', partial: 'barcode_entry'
              page << "$('family_barcode_id').focus(); $('family_barcode_id').select();"
            end
          end
        end
      end
    else
      render plain: t('families.not_found'), status: 404
    end
  end

  def new
  end

  def create
    respond_to do |format|
      if @family.save
        format.html { redirect_to @family, notice: t('families.new.created.notice') }
        format.xml  { render xml: @family, status: :created, location: @family }
      else
        format.html { render action: 'new' }
        format.xml  { render xml: @family.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    @updater = FamilyUpdater.new(params)
    @family = @updater.family
    safe_redirect_path = params[:redirect_to].present? ? URI.parse(params[:redirect_to]).path : @family
    if @updater.save!
      respond_to do |format|
        format.html { flash[:notice] = t('families.edit.saved'); redirect_to(safe_redirect_path) }
        format.xml  { render xml: @family.to_xml } if can_export?
      end
    else
      respond_to do |format|
        format.html { render action: 'edit' }
        format.xml  { render xml: @family.errors, status: :unprocessable_entity } if can_export?
        format.js do # only used by barcode entry right now
          render :update do |page|
            page.replace_html :notice, t('There_were_errors') + ":<br/>#{@family.errors.values.join('; ')}"
            page[:notice].show
          end
        end
      end
    end
  end

  def destroy
    if @family == @logged_in.family
      flash[:warning] = t('families.delete.cannot_delete_your_own')
      redirect_to @family
    else
      @family.destroy
      redirect_to people_path
    end
  end

  def batch
    # delete family (used by Administration::DeletedPeopleController)
    if @logged_in.admin?(:edit_profiles) && params[:delete]
      params[:ids].to_a.each do |id|
        Family.find(id).destroy
      end
      redirect_back
    else
      render plain: t('not_authorized'), layout: true, status: 401
    end
  end

  def select
    @family = Family.find(params[:id]) unless params[:id].blank?
    respond_to do |format|
      format.html { redirect_to new_person_path(family_id: @family) }
      format.js
    end
  end

  private

  def family_params
    params.require(:family).permit(:legacy_id, :barcode_id, :alternate_barcode_id, :name, :last_name, :address1, :address2, :city, :state, :zip, :home_phone, :email, :share_address, :share_mobile_phone, :share_work_phone, :share_fax, :share_email, :share_birthday, :share_anniversary, :visible, :share_activity, :share_home_phone, :photo)
  end
end
