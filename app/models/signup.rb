require 'active_model'

class Signup
  include ActiveModel::Validations

  PARAMS = [:email, :password, :password_confirmation, :first_name, :last_name, :gender, :birthday, :a_phone_number]

  attr_accessor *PARAMS
  attr_accessor :family, :person

  validates :email, :first_name, :last_name, :gender, :birthday, presence: true
  validate :validate_adult
  validate :validate_not_a_bot
  validate :validate_sign_up_allowed

  def initialize(params={})
    PARAMS.each do |field|
      instance_variable_set "@#{field}", params[field]
    end
  end

  def save
    return false unless valid?
    return false unless create_family and create_person
    if sign_up_approval_required?
      deliver_signup_approval
    else
      create_and_deliver_verification
    end
    true
  end

  def save!
    raise ArgumentError.new(errors.full_messages) unless valid?
    save
  end

  protected

  def create_family
    @family = Family.create(
      name: "#{first_name} #{last_name}",
      last_name: last_name
    )
    @family.errors.empty?
  end

  def create_person
    @person = @family.people.create(
      email: email,
      first_name: first_name,
      last_name: last_name,
      birthday: birthday,
      gender: gender,
      can_sign_in: full_access?,
      full_access: full_access?,
      visible_to_everyone: full_access?,
      visible_on_printed_directory: full_access?
    )
    @person.errors.empty?
  end

  def deliver_signup_approval
    Notifier.pending_sign_up(@person).deliver
  end

  def full_access?
    !sign_up_approval_required?
  end

  def create_and_deliver_verification
    verification = Verification.create!(email: @person.email)
    Notifier.email_verification(verification).deliver
  end

  def sign_up_approval_required?
    Setting.get(:features, :sign_up_approval_email).present?
  end

  def validate_adult
    unless Person.new(birthday: @birthday).adult?
      errors.add(:birthday, :too_young)
    end
  end

  def validate_sign_up_allowed
    unless Setting.get(:features, :sign_up)
      errors.add(:base, :disabled)
    end
  end

  def validate_not_a_bot
    if @a_phone_number.present?
      errors.add(:base, :spam)
    end
  end

end
