class FamiliesController < ApplicationController

  load_and_authorize_resource except: [:show, :hashify, :batch, :select, :schema]

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
    if params[:legacy_id]
      @family = Family.where(legacy_id: params[:id]).first
    elsif params[:barcode_id]
      @family = Family.where(barcode_id: params[:id], deleted: false).first ||
        Family.where(alternate_barcode_id: params[:id], deleted: false).first
    else
      @family = Family.where(id: params[:id], deleted: false).first
    end
    raise ActiveRecord::RecordNotFound unless @family
    @people = @family.people.undeleted.to_a.select { |p| @logged_in.can_read?(p) }
    if @logged_in.can_read?(@family)
      respond_to do |format|
        format.html
        format.xml  { render xml: @family.to_xml } if can_export?
        format.json { render text: @family.to_json(except: %w(site_id)) } if can_export?
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
      render text: t('families.not_found'), status: 404
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
        format.html { render action: "new" }
        format.xml  { render xml: @family.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    @updater = FamilyUpdater.new(params)
    @family = @updater.family
    if @updater.save!
      respond_to do |format|
        format.html { flash[:notice] = t('families.edit.saved'); redirect_to params[:redirect_to] || @family }
        format.xml  { render xml: @family.to_xml } if can_export?
      end
    else
      respond_to do |format|
        format.html { render action: 'edit' }
        format.xml  { render xml: @family.errors, status: :unprocessable_entity } if can_export?
        format.js do # only used by barcode entry right now
          render :update do |page|
            page.replace_html :notice, t('There_were_errors') + ":<br/>#{@family.errors.full_messages.join('; ')}"
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

  def hashify
    params.merge!(Hash.from_xml(request.body.read))
    if @logged_in.admin?(:import_data) and Site.current.import_export_enabled?
      ids = params[:hash][:legacy_id].to_s.split(',')
      raise 'error' if ids.length > 1000
      hashes = Family.hashify(legacy_ids: ids, attributes: params[:hash][:attrs].split(','), debug: params[:hash][:debug])
      render xml: hashes.to_a
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  def batch
    # delete family (used by Administration::DeletedPeopleController)
    if @logged_in.admin?(:edit_profiles) and params[:delete]
      params[:ids].to_a.each do |id|
        Family.find(id).destroy
      end
      redirect_back
    # API for use by UpdateAgent
    elsif @logged_in.admin?(:import_data) and Site.current.import_export_enabled?
      xml_params = Hash.from_xml(request.body.read)['hash']
      statuses = Family.update_batch(xml_params['records'], xml_params['options'] || {})
      respond_to do |format|
        format.xml { render xml: statuses }
      end
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  def select
    @family = Family.find(params[:id]) unless params[:id].blank?
    respond_to do |format|
      format.html { redirect_to new_person_path(family_id: @family) }
      format.js
    end
  end

  def schema
    render xml: Family.columns.map { |c| {name: c.name, type: c.type} }
  end

  private

  def family_params
    params.require(:family).permit(:legacy_id, :barcode_id, :alternate_barcode_id, :name, :last_name, :address1, :address2, :city, :state, :zip, :home_phone, :email, :share_address, :share_mobile_phone, :share_work_phone, :share_fax, :share_email, :share_birthday, :share_anniversary, :visible, :share_activity, :share_home_phone, :photo)
  end
end
