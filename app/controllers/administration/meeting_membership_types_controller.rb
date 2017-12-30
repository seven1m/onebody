class Administration::MeetingMembershipTypesController < ApplicationController
    def index
        unless @logged_in.admin?(:manage_meeting_membership_types)
            render html: t('not_authorized'), layout: true, status: 401
            return
        end

        @title = 'Meeting Membership Types'
        @meeting_membership_types = MeetingMembershipType.all()
        @meeting_membership_type = MeetingMembershipType.new()
        @formUrl = administration_meeting_membership_types_path
    end

    def show
        unless @logged_in.admin?(:manage_meeting_membership_types)
            render html: t('not_authorized'), layout: true, status: 401
            return
        end

        @meeting_membership_type = MeetingMembershipType.find(params[:id])
        @formUrl = administration_meeting_membership_type_path(@meeting_membership_type)
        @members = @meeting_membership_type.meeting_memberships.includes(:person).map(&:person)
    end

    def update
        unless @logged_in.admin?(:manage_meeting_membership_types)
            render html: t('not_authorized'), layout: true, status: 401
            return
        end

        @meeting_membership_type = MeetingMembershipType.find(params[:id])
        if @meeting_membership_type.update_attributes(meeting_membership_type_params)
            flash[:notice] = 'Meeting Membership Type Saved'
            redirect_to administration_meeting_membership_type_path(@meeting_membership_type)
        else
            render action: 'index'
        end
    end

    def new
        unless @logged_in.admin?(:manage_meeting_membership_types)
            render html: t('not_authorized'), layout: true, status: 401
            return
        end
            @meeting_membership_type = MeetingMembershipType.new()
            @formUrl = administration_meeting_membership_types_path
    end

    def create
        unless @logged_in.admin?(:manage_meeting_membership_types)
            render html: t('not_authorized'), layout: true, status: 401
            return
        end

        @meeting_membership_type = MeetingMembershipType.new(meeting_membership_type_params)
        if @meeting_membership_type.save
            if @logged_in.admin?(:manage_meeting_membership_types)
                flash[:notice] = 'Meeting Membership Type Created'
            end
            redirect_to administration_meeting_membership_type_path(@meeting_membership_type)
        else
            render action: 'new'
        end
    end

    def meeting_membership_type_attributes
        %i(name)
    end
    
    def meeting_membership_type_params
        params.require(:meeting_membership_type).permit(*meeting_membership_type_attributes)
    end
end