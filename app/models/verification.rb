class Verification < ApplicationRecord
  MIN_CODE = 100_000
  MAX_CODE = 999_999

  scope_by_site_id

  scope :pending, -> { where(verified: nil) }

  validates :criteria, presence: true
  validates :carrier, inclusion: MOBILE_GATEWAYS.keys, if: -> { mobile_phone }
  validate :validate_max_attempts, on: :create
  validate :validate_people, if: -> { email || mobile_phone }
  validate :validate_people_able_to_sign_in, if: -> { email || mobile_phone }

  blank_to_nil :mobile_phone, :email

  def validate_people
    unless people.any?
      field = mobile_phone ? :mobile_phone : :email
      errors.add(field, :invalid)
    end
  end

  def validate_people_able_to_sign_in
    return if people.none?
    return if people.any?(&:able_to_sign_in?)
    errors.add(:base, :unauthorized)
  end

  def criteria(for_verification = false)
    if mobile_phone
      { mobile_phone: mobile_phone.digits_only }
    elsif email && for_verification
      { email: email }
    elsif email
      ['email = :email or alternate_email = :email', email: email]
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

  after_create :send_verification_email

  def email
    read_attribute(:email) || mobile_gateway_email
  end

  def mobile_gateway_email
    if gateway = MOBILE_GATEWAYS[carrier]
      gateway % mobile_phone.digits_only
    end
  end

  def send_verification_email
    if verified.nil?
      if mobile_phone
        Notifier.mobile_verification(self).deliver_now
      else
        Notifier.email_verification(self).deliver_now
      end
    end
  rescue Errno::ECONNREFUSED, Net::SMTPAuthenticationError => e
    raise EmailConnectionError, e.message
  end

  def check(param)
    pending? && param.to_i == code
  end

  def check!(param)
    return false unless pending?
    self.verified = (param.to_i == code && people.any?)
    save!
    verified
  end

  def pending?
    read_attribute(:verified).nil?
  end

  def validate_max_attempts
    count = Verification.where(criteria(:for_verification)).where('created_at > ?', 1.day.ago).count
    if count >= MAX_DAILY_VERIFICATION_ATTEMPTS
      errors.add :base, I18n.t('accounts.verification_max_attempts_reached')
      return false
    end
  end
end
