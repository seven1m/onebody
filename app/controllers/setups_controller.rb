class SetupsController < ApplicationController

  skip_before_filter :authenticate_user
  before_filter :check_setup_requirements

  def show
    redirect_to new_setup_path
  end

  def new
    generate_encryption_key
    @person = Person.new
  end

  def create
    Person.transaction do
      @person = Person.new
      if params[:domain_name].to_s.any?
        Site.current.host = params[:domain_name]
        Site.current.save
      else
        generate_encryption_key
        @person.errors.add :base, t('setup.invalid_domain_name')
        render action: 'new'
        return
      end
      @person.attributes = params[:person]
      @person.password = params[:encrypted_password].to_s.any? ? decrypt_password(params[:encrypted_password]) : nil
      @person.password_confirmation = params[:encrypted_password_confirmation].to_s.any? ? decrypt_password(params[:encrypted_password_confirmation]) : nil
      unless @person.password and @person.password == @person.password_confirmation
        generate_encryption_key
        @person.errors.add :error, t('accounts.set_password_error')
        render action: 'new'
        return
      end
      unless @person.email.to_s.any?
        generate_encryption_key
        @person.errors.add :email, t('activerecord.errors.models.person.attributes.email.invalid')
        render action: 'new'
        return
      end
      @person.can_sign_in = true
      @person.visible_to_everyone = true
      @person.visible_on_printed_directory = true
      @person.full_access = true
      @person.child = false
      @person.family = Family.create!(
        name:      @person.name,
        last_name: @person.last_name
      )
      @person.admin = Admin.create!(super_admin: true)
      if @person.save
        Setting.set_global('Contact', 'Bug Notification Email', @person.email)
        Setting.set_global('Contact', 'Tech Support Email', @person.email)
        flash[:notice] = t('setup.complete')
        redirect_to new_session_path(from: '/stream')
      else
        generate_encryption_key
        render action: 'new'
        raise ActiveRecord::Rollback
      end
    end
  end

  private

    def check_setup_requirements
      if Person.count > 0 or Setting.get(:features, :multisite)
        render text: t('not_authorized'), layout: true
        return false
      end
    end

end
