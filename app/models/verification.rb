class Verification < ActiveRecord::Base

  MIN_CODE = 100000
  MAX_CODE = 999999

  belongs_to :site

  scope_by_site_id

  scope :pending, -> { where(verified: nil) }

  validates :criteria, presence: true
  validates :carrier, inclusion: MOBILE_GATEWAYS.keys, if: -> { mobile_phone }
  validate :validate_max_attempts
  validate :validate_people, if: -> { email or mobile_phone }

  blank_to_nil :mobile_phone, :email

  def validate_people
    unless people.any?
      field = mobile_phone ? :mobile_phone : :email
      errors.add(field, :invalid)
    end
  end






  def create_by_email
    person = Person.find_by_email(params[:email])
    family = Family.find_by_email(params[:email])
    if person or family
      if (person and person.can_sign_in?) or (family and family.people.any? and family.people.first.can_sign_in?)
        v = Verification.create email: params[:email]
        if v.errors.any?
          render text: v.errors.full_messages.join('; '), layout: true
        else
          Notifier.email_verification(v).deliver
          render text: t('accounts.verification_email_sent'), layout: true
        end
      else
        redirect_to page_for_public_path('system/bad_status')
      end
    else
      render text: t('accounts.email_not_found'), layout: true
    end
  end

  def create_by_mobile
    mobile = params[:phone].scan(/\d/).join('')
    person = Person.find_by_mobile_phone(mobile)
    if person
      if person.can_sign_in?
        unless gateway = MOBILE_GATEWAYS[params[:carrier]]
          raise 'Error.'
        end
        v = Verification.create email: gateway % mobile, mobile_phone: mobile
        if v.errors.any?
          render text: v.errors.full_messages.join('; '), layout: true
        else
          Notifier.mobile_verification(v).deliver
          render text: t('accounts.verification_message_sent'), layout: true
        end
      else
        redirect_to page_for_public_path('system/bad_status')
      end
    else
      flash[:warning] = t('accounts.mobile_number_not_found')
      @signup = Signup.new
      render action: 'new'
    end
  end

  def create_by_birthday
    if params[:name].to_s.any? and params[:email].to_s.any? and params[:phone].to_s.any? and params[:birthday].to_s.any? and params[:notes].to_s.any?
      Notifier.birthday_verification(params[:name], params[:email], params[:phone], params[:birthday], params[:notes]).deliver
      render text: t('accounts.submission_will_be_reviewed'), layout: true
    else
      flash[:warning] = t('accounts.fill_required_fields')
      @signup = Signup.new
      render action: 'new'
    end
  end

  def criteria
    if mobile_phone
      {mobile_phone: mobile_phone}
    elsif email
      {email: email}
    end
  end

  def people
    Person.where(criteria)
  end

  def initialize(*args)
    super
    generate_security_code
  end

  def generate_security_code
    code = SecureRandom.random_number(MAX_CODE - MIN_CODE) + MIN_CODE
    write_attribute :code, code
  end

  before_create :send_verification_email

  def email
    read_attribute(:email) || mobile_gateway_email
  end

  def mobile_gateway_email
    if gateway = MOBILE_GATEWAYS[carrier]
      gateway % mobile_phone
    end
  end

  def send_verification_email
    if verified.nil?
      if mobile_phone
        Notifier.mobile_verification(self).deliver
      else
        Notifier.email_verification(self).deliver
      end
    end
  end

  def check!(param)
    self.verified = (param.to_i == code and people.any?)
    save!
    self.verified
  end

  def pending?
    read_attribute(:verified).nil?
  end

  def validate_max_attempts
    count = Verification.where(criteria).where('created_at > ?', 1.day.ago).count
    if count >= MAX_DAILY_VERIFICATION_ATTEMPTS
      errors.add :base, I18n.t('accounts.verification_max_attempts_reached')
      return false
    end
  end
end
