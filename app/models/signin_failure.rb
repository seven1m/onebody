class SigninFailure < ActiveRecord::Base
  scope :matching, lambda { |request|
    where(email: request.params[:email].downcase, ip: request.remote_ip).where('created_at >= ?', 15.minutes.ago)
  }
end
