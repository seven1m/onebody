class CustomReportAuthorizer < ApplicationAuthorizer
  def readable_by?(user)
    user.admin?(:run_reports)
  end

  def creatable_by?(user)
    user.admin?(:manage_reports)
  end

  alias_method :updatable_by?, :creatable_by?
  alias_method :deletable_by?, :creatable_by?
end
