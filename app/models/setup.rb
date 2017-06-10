class Setup
  attr_reader :person
  attr_reader :site

  def initialize(params)
    @params = params
    @site = Site.current
  end

  def execute!
    Person.transaction do
      @person = Person.new
      assign_params_to_person
      unless update_host!
        @site.errors
        @site.errors.values.each do |msg|
          @person.errors.add :base, msg
        end
        return false
      end
      if update_person!
        update_admin_settings!
        update_stream_item!
        true
      else
        puts 'update_person error'
        raise ActiveRecord::Rollback
        false
      end
    end
  end

  def assign_params_to_person
    @person.first_name = @params[:person][:first_name]
    @person.last_name  = @params[:person][:last_name]
    @person.email      = @params[:person][:email]
  end

  def update_person!
    @person.password = @params[:person][:password].presence
    @person.password_confirmation = @params[:person][:password_confirmation].presence
    unless @person.password && @person.password == @person.password_confirmation
      @person.errors.add :error, I18n.t('accounts.set_password_error')
      return false
    end
    unless @person.email.present?
      @person.errors.add :email, I18n.t('activerecord.errors.models.person.attributes.email.invalid')
      return false
    end
    @person.status = :active
    @person.child = false
    @person.family = Family.create!(
      name:      @person.name,
      last_name: @person.last_name
    )
    @person.admin = Admin.create!(super_admin: true)
    @person.save
  end

  def update_host!
    if @params[:domain_name].present?

      @site.host = @params[:domain_name]
      @site.save
    else
      @person.errors.add :base, I18n.t('setup.domain_name_note')
      false
    end
  end

  def update_admin_settings!
    Setting.set_global('Contact', 'Bug Notification Email', @person.email)
    Setting.set('Contact', 'Tech Support Email', @person.email)
  end

  def update_stream_item!
    @site.update_stream_item(@person)
  end
end
