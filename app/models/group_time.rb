class GroupTime < ActiveRecord::Base
  belongs_to :group
  belongs_to :checkin_time

  validates_exclusion_of :section, in: ['', '!']

  scope_by_site_id

  def section=(s)
    self[:section] = nil unless s.present?
  end

  before_create :update_ordering
  def update_ordering
    if checkin_time and ordering.nil?
      scope = checkin_time.group_times
      scope = scope.where.not(id: id) unless new_record?
      self.ordering = scope.maximum(:ordering).to_i + 1
    end
  end

  def self.section_names
    connection.select_values("select distinct section from group_times where section is not null and section != '' and site_id=#{Site.current.id} order by section")
  end
end
