class GroupTime < ActiveRecord::Base
  belongs_to :group
  belongs_to :checkin_folder
  belongs_to :checkin_time

  default_scope -> { order(:sequence) }

  scope_by_site_id

  def parent
    checkin_folder || checkin_time
  end

  def time
    checkin_time || checkin_folder.try(:checkin_time)
  end

  # FIXME!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  before_create :update_ordering
  def update_ordering
    if checkin_time and ordering.nil?
      scope = checkin_time.group_times
      scope = scope.where.not(id: id) unless new_record?
      self.ordering = scope.maximum(:ordering).to_i + 1
    end
  end
end
