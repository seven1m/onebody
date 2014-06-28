class GroupTime < ActiveRecord::Base
  belongs_to :group
  belongs_to :checkin_time

  validates_exclusion_of :section, in: ['!']

  scope_by_site_id

  def self.section_names
    connection.select_values("select distinct section from group_times where section is not null and section != '' and site_id=#{Site.current.id} order by section")
  end
end
