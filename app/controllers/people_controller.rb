class PeopleController < ApplicationController

  def index
    respond_to do |format|
      format.html { redirect_to person_path(@logged_in) }
      if can_export?
        format.xml do
          job = Person.create_to_xml_job
          redirect_to generated_file_path(job.id)
        end
        format.csv do
          job = Person.create_to_csv_job
          redirect_to generated_file_path(job.id)
        end
      end
    end
  end

  def show
    if params[:id].to_i == session[:logged_in_id]
      @person = @logged_in
    elsif params[:legacy_id]
      @person = Person.where(legacy_id: params[:id]).includes(:family).first
    else
      @person = Person.where(id: params[:id]).includes(:family).first
    end
    if params[:limited] or !@logged_in.full_access?
      render action: 'show_limited'
    elsif @person and @logged_in.can_see?(@person)
      @family = @person.family
      if @person == @logged_in
        # TODO eager load family here
        @family_people = (@person.family.try(:people) || []).reject(&:deleted)
      else
        @family_people = @person.family.try(:visible_people) || []
      end
      @albums = @person.albums.order(created_at: :desc)
      @friends = @person.friends.minimal
      @verses = @person.verses.order(:book, :chapter, :verse)
      if params[:business]
        render action: 'business'
      else
        respond_to do |format|
          format.html
          format.xml { render xml: @person.to_xml } if can_export?
        end
      end
    elsif @person and @person.deleted? and @logged_in.admin?(:edit_profiles)
      @deleted_people_url = administration_deleted_people_path('search[id]' => @person.id)
      render text: t('people.deleted_html', url: @deleted_people_url), status: 404, layout: true
    else
      render text: t('people.not_found'), status: 404, layout: true
    end
  end

  def new
    if @logged_in.admin?(:edit_profiles)
      @family = Family.find(params[:family_id])
      @person = @family.people.new
      @person.set_default_visibility
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  def create
    if Person.can_create?
      if @logged_in.admin?(:edit_profiles)
        @business_categories = Person.business_categories
        @custom_types = Person.custom_types
        params[:person].cleanse(:birthday, :anniversary)
        @person = Person.new_with_default_sharing(person_params)
        @person.family_id = params[:person][:family_id]
        respond_to do |format|
          if @person.save
            format.html { redirect_to @person.family }
            format.xml  { render xml: @person, status: :created, location: @person }
          else
            format.html { render action: "new" }
            format.xml  { render xml: @person.errors, status: :unprocessable_entity }
          end
        end
      else
        render text: t('not_authorized'), layout: true, status: 401
      end
    else
      render text: t('people.cant_be_added'), layout: true, status: 401
    end
  end

  def edit
    @person ||= Person.find(params[:id])
    if @logged_in.can_edit?(@person)
      @family = @person.family
      @business_categories = Person.business_categories
      @custom_types = Person.custom_types
      if params[:email]
        render action: 'email'
      else
        render action: 'edit'
      end
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  def update
    @person = Person.find(params[:id])
    if @logged_in.can_edit?(@person)
      @updater = Updater.new(params)
      if @updater.save!
        respond_to do |format|
          format.html do
            flash[:notice] = t('people.changes_submitted')
            flash[:show_verification_link] = @updater.changes[:person].try(:[], :can_sign_in)
            redirect_to @person
          end
          format.xml { render xml: @person.to_xml } if can_export?
        end
      else
        @person = @updater.person
        edit
      end
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  def destroy
    if @logged_in.admin?(:edit_profiles)
      @person = Person.find(params[:id])
      if me?
        render text: t('people.cant_delete_yourself'), layout: true, status: 401
      elsif @person.global_super_admin?
        render text: t('people.cant_delete'), layout: true, status: 401
      else
        @person.destroy
        redirect_to @person.family
      end
    else
     render text: t('not_authorized'), layout: true, status: 401
    end
  end

  def import
    if @logged_in.admin?(:import_data) and Site.current.import_export_enabled?
      if request.get?
        @column_names = Person.importable_column_names
      elsif request.post?
        @records = Person.queue_import_from_csv_file(params[:file].read, params[:match_by_name], params[:attributes])
        render action: 'import_queue'
      elsif request.put?
        @completed, @errored = Person.import_data(params)
        render action: 'import_results'
      end
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  def hashify
    if @logged_in.admin?(:import_data) and Site.current.import_export_enabled?
      ids = params[:hash][:legacy_id].to_s.split(',')
      raise t('families.too_many') if ids.length > 1000
      hashes = Person.hashify(legacy_ids: ids, attributes: params[:hash][:attrs].split(','), debug: params[:hash][:debug])
      render xml: hashes
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  def batch
    # post from families/show page
    if params[:family_id] and @logged_in.admin?(:edit_profiles)
      params[:ids].each { |id| Person.find(id).update_attribute(:family_id, params[:family_id]) }
      respond_to do |format|
        format.html { redirect_to family_path(params[:family_id]) }
        format.js   { render js: "location.replace('#{family_path(params[:family_id])}')" }
      end
    # API for use by UpdateAgent
    elsif @logged_in.admin?(:import_data) and Site.current.import_export_enabled?
      xml_params = Hash.from_xml(request.body.read)['hash']
      statuses = Person.update_batch(xml_params['records'], xml_params['options'] || {})
      respond_to do |format|
        format.xml { render xml: statuses }
      end
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  def schema
    render xml: Person.columns.map { |c| {name: c.name, type: c.type} }
  end

  def favs
    @person = Person.find(params[:id])
    unless @logged_in.can_see?(@person)
      render text: t('people.not_found'), status: 404, layout: true
    end
  end

  def testimony
    @person = Person.find(params[:id])
    unless @logged_in.can_see?(@person)
      render text: t('people.not_found'), status: 404, layout: true
    end
  end

  private

  # FIXME this is temporary
  def person_params
    Updater.new(params).params[:person]
  end

end
