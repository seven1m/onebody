class CheckinFolder < ActiveRecord::Base
  include Concerns::Reorder

  belongs_to :checkin_time
  has_many :group_times, dependent: :destroy
  has_many :groups, through: :group_times

  scope_by_site_id

  default_scope -> { order(:sequence) }

  def time; checkin_time; end
  def entries; group_times; end
  def parent; checkin_time; end
  def checkin_folder_id; nil; end
end
