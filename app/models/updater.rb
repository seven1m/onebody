# This is the object that queues a profile update and
# delegates those changes to the Person and Family models.

class Updater
  # specify how to handle changes per attribute
  # :approve = create a pending update that must be approved by an admin
  #            (unless the 'Update Must Be Approved' setting is disabled, in which case it is same as :immediate)
  # :immediate = save change directly to model
  # :notify = save change directly to model and send notification email to admins
  # :admin = only save changes if current user is an administrator
  PARAMS = {
    person: {
      first_name:           :approve,
      last_name:            :approve,
      suffix:               :approve,
      alias:                :approve,
      gender:               :approve,
      mobile_phone:         :approve,
      work_phone:           :approve,
      fax:                  :approve,
      birthday:             :approve,
      anniversary:          :approve,
      description:          :immediate,
      website:              :immediate,
      about:                :immediate,
      testimony:            :immediate,
      share_:               :immediate,
      business_:            :immediate,
      alternate_email:      :immediate,
      visible:              :immediate,
      messages_enabled:     :immediate,
      friends_enabled:      :immediate,
      photo:                :immediate,
      facebook_url:         :immediate,
      twitter:              :immediate,
      primary_emailer:      :immediate,
      email:                :notify,
      classes:              :admin,
      shepherd:             :admin,
      mail_group:           :admin,
      member:               :admin,
      staff:                :admin,
      elder:                :admin,
      deacon:               :admin,
      child:                :admin,
      custom_type:          :admin,
      fields:               :admin,
      medical_notes:        :admin,
      can_pick_up:          :admin,
      cannot_pick_up:       :admin,
      position:             :admin,
      family_id:            :admin,
      legacy_id:            :admin,
      legacy_family_id:     :admin,
      relationships:        :admin,
      status:               :admin
    },
    family: {
      name:                 :approve,
      last_name:            :approve,
      home_phone:           :approve,
      address1:             :approve,
      address2:             :approve,
      city:                 :approve,
      state:                :approve,
      zip:                  :approve,
      country:              :approve,
      share_:               :immediate,
      visible:              :immediate,
      photo:                :immediate,
      email:                :admin,
      legacy_id:            :admin,
      barcode_id:           :admin,
      alternate_barcode_id: :admin
    }
  }.freeze

  def initialize(params)
    params = params.to_unsafe_h unless params.is_a?(Hash) # we filter them manually
    self.params = params
  end

  # all params
  def params
    filter_params { |_, _, _, val| val }
  end

  # set new params
  def params=(p)
    @id = p.delete(:id)
    @person = @changes = nil # reset cache
    @params = ActionController::Parameters.new(p)
  end

  # shows which fields would be affected if the update were applied
  def changes
    @changes ||= begin
      h = HashWithIndifferentAccess.new
      h[:person] = Comparator.new(person, params[:person]).changes if person
      h[:family] = Comparator.new(family, params[:family]).changes if family
      h.reject { |_, v| v.empty? }
    end
  end

  # updates models if appropriate
  # and/or creates a new Update pending approval
  def save!
    changes # set cache
    person.updates.create!(family_id: family.id, data: approval_params) unless approval_params.empty?
    success = person.update_attributes(person_params) && family.update_attributes(family_params)
    family.errors.values.each { |m| person.errors.add(:base, m) } unless success
    success
  end

  def person
    @person ||= Person.find(@id)
  end

  def family
    @family ||= person.family
  end

  def show_verification_link?
    person.able_to_sign_in? &&
      (changes[:person].try(:[], :email) || changes[:person].try(:[], :status))
  end

  private

  # params that should update the model directly without approval
  def immediate_params
    filter_params do |access, _, _, val|
      val if immediate_access_types.include?(access)
    end
  end

  # params that require approval
  def approval_params
    filter_params do |access, section, key, val|
      if access == :approve &&
          changes[section].try(:[], key) &&
          approvals_enabled? &&
          !admin?
        val
      end
    end
  end

  # returns only params that are allowed by the supplied block
  def filter_params(section = nil, unfiltered = @params, spec = PARAMS, &block)
    ActionController::Parameters.new.tap do |permitted|
      unfiltered.each do |key, val|
        if access = find_spec(spec, key)
          if Hash === access
            permitted[key] = filter_params(key, val, access, &block)
            permitted[key].permit!
          elsif val = yield(access, section, key, val)
            val = cleanse_value(val)
            permitted[key] = val
          end
        end
      end
      permitted.permit!
      permitted.reject! { |_, v| v.is_a?(ActionController::Parameters) && v.empty? }
    end
  end

  # converts empty string to nil
  def cleanse_value(value)
    value = value.strip if value.is_a?(String)
    value if value.present?
  end

  # given a key, find corresponding spec/access (value) from supplied spec hash
  def find_spec(spec, key)
    wildcard = key.to_s.split('_').first + '_' # e.g. share_
    spec[key.to_sym] || spec[wildcard.to_sym]
  end

  # types of access that allow attributes to be updated on model immediately
  # (no approval necessary)
  def immediate_access_types
    %i(immediate notify).tap do |base|
      base << :approve if admin? || !approvals_enabled?
      base << :admin if admin?
    end
  end

  def person_params
    immediate_params.fetch(:person, {})
  end

  def family_params
    immediate_params.fetch(:family, {})
  end

  def admin?
    Person.logged_in.admin?(:edit_profiles)
  end

  def approvals_enabled?
    Setting.get(:features, :updates_must_be_approved)
  end
end
