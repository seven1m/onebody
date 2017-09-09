class Administration::AdminsController < ApplicationController
  before_action :only_admins

  def index
    if params[:groups]
      @group_admins = Membership.where(admin: true).includes(:group, :person) \
                                .map { |m| [m.person, m.group] } \
                                .sort_by { |a| (params[:sort] == 'group' ? a[1] : a[0]).name }
      render action: 'group_admins'
    else
      @order = case params[:order]
               when 'template'
                 'admins.super_admin, admins.template_name, people.last_name, people.first_name'
               else
                 'people.last_name, people.first_name'
               end
      @people = Person.where('admin_id is not null').order(@order).includes(:admin)
      @templates = Admin.where('template_name is not null').order(:template_name).select('*, (select count(*) from people where admin_id=admins.id) as people_count')
    end
  end

  def edit
    @admin = Admin.find(params[:id])
    @people = @admin.people.order('last_name, first_name')
  end

  def update
    @admin = Admin.find(params[:id])
    Admin.privileges.each do |priv|
      @admin.flags[priv] = params[:privileges] && params[:privileges][priv] == 'true'
    end
    if @logged_in.super_admin?
      if @admin.super_admin = params[:super_admin] == 'true'
        Admin.privileges.each do |priv|
          @admin.flags[priv] = false
        end
      end
    end
    flash[:notice] = t('Changes_saved')
    @admin.save!
    redirect_to administration_admins_path
  end

  def create
    flash[:notice] = ''
    params[:ids].to_a.each do |id|
      if Site.current.max_admins.nil? || Admin.people_count < Site.current.max_admins
        person = Person.find(id)
        if person.admin?
          flash[:notice] += t('admin.already_admin', name: person.name) + ' '
        else
          person.admin = params[:template_id].to_i > 0 ? Admin.find(params[:template_id]) : Admin.create!
          person.save!
          if person.save
            flash[:notice] += t('admin.admin_added', name: person.name) + ' '
          else
            add_errors_to_flash(person)
          end
        end
      else
        flash[:notice] += t('admin.no_more_admins') + ' '
        break
      end
    end
    if params[:template_name]
      Admin.create!(template_name: params[:template_name])
      flash[:notice] += t('application.template_created')
    end
    if params[:redirect_to]
      redirect_to URI.parse(params[:redirect_to]).path
    else
      redirect_to administration_admins_path
    end
  end

  def destroy
    @admin = Admin.find(params[:id])
    if params[:person_id]
      @person = Person.find(params[:person_id])
      @person.update_attribute(:admin_id, nil)
      respond_to do |format|
        format.html
        format.js
      end
    else
      @admin.destroy
      flash[:notice] = t('admin.admin_removed')
      redirect_to administration_admins_path
    end
  end

  private

  def only_admins
    unless @logged_in.admin?(:manage_access)
      render html: t('only_admins'), layout: true, status: 401
      false
    end
  end
end
