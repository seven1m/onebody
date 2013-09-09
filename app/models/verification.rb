class Verification < ActiveRecord::Base

  MIN_CODE = 100000
  MAX_CODE = 999999

  belongs_to :site

  scope_by_site_id

  scope :pending, -> { where(verified: nil) }

  validates_presence_of :criteria
  validate :validate_max_attempts

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
