class ParentalConsent
  extend ActiveModel::Naming

  attr_reader :errors

  def initialize(child, user, agreement)
    @child = child
    @user = user
    @agreement = agreement
    @errors = ActiveModel::Errors.new(self)
  end

  def perform
    return false unless valid?
    @child.parental_consent = "#{@user.name} (#{@user.id}) #{Time.current}"
    @child.save(validate: false)
  end

  def valid?
    validate
    @errors.empty?
  end

  def authorized?
    @user.family == @child.family &&
      @user.family &&
      @user.adult? &&
      @user.can_update?(@child.family)
  end

  def agreed?
    @agreement == I18n.t('privacies.i_agree') + '.'
  end

  private

  def validate
    @errors.clear
    @errors.add(:base, I18n.t('not_authorized')) unless authorized?
    @errors.add(:base, I18n.t('privacies.you_must_check_agreement_statement')) unless agreed?
  end
end
