class Verification < ActiveRecord::Base
  belongs_to :site

  scope_by_site_id

  before_create :generate_security_code

  def generate_security_code
    conditions = ['created_at >= ? and email = ?', Date.today, email]
    if Verification.count(:conditions => conditions) >= MAX_DAILY_VERIFICATION_ATTEMPTS
      errors.add :base, 'You have exceeded the daily limit for verification attempts.'
      return false
    else
      begin
        code = rand(999999)
        write_attribute :code, code
      end until code > 0
    end
  end

  def pending?
    read_attribute(:verified).nil?
  end
end
