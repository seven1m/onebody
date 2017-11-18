class Administration::RolesController < ApplicationController
    def index
        unless @logged_in.admin?(:manage_roles)
            render html: t('not_authorized'), layout: true, status: 401
            return
        end

        @title = I18n.t('admin.roles.heading')
        @roles = Role.all()
        @role = Role.new()
        @formUrl = administration_roles_path
    end

    def show
        unless @logged_in.admin?(:manage_roles)
            render html: t('not_authorized'), layout: true, status: 401
            return
        end

        @role = Role.find(params[:id])
        @formUrl = administration_role_path(@role)
        @members = @role.role_memberships.includes(:person).map(&:person)
    end

    def update
        unless @logged_in.admin?(:manage_roles)
            render html: t('not_authorized'), layout: true, status: 401
            return
        end

        @role = Role.find(params[:id])
        if @role.update_attributes(role_params)
            flash[:notice] = t('admin.roles.saved')
            redirect_to administration_role_path(@role)
        else
            render action: 'index'
        end
    end

    def new
        unless @logged_in.admin?(:manage_roles)
            render html: t('not_authorized'), layout: true, status: 401
            return
        end
            @role = Role.new()
            @formUrl = administration_roles_path
    end

    def create
        unless @logged_in.admin?(:manage_roles)
            render html: t('not_authorized'), layout: true, status: 401
            return
        end

        @role = Role.new(role_params)
        if @role.save
            if @logged_in.admin?(:manage_roles)
                flash[:notice] = t('roles.created')
            end
            redirect_to administration_role_path(@role)
        else
            render action: 'new'
        end
    end

    def role_attributes
        %i(name)
    end
    
    def role_params
        params.require(:role).permit(*role_attributes)
    end

end