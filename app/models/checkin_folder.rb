class CheckinFolder < ApplicationRecord
  include Concerns::Reorder

  belongs_to :checkin_time
  has_many :group_times, dependent: :destroy
  has_many :groups, through: :group_times

  scope_by_site_id

  default_scope -> { order(:sequence) }

  before_create { parent&.update_sequence(self) }

  validates :name, uniqueness: { scope: :checkin_time }

  def time
    checkin_time
  end

  def entries
    group_times
  end

  def parent
    checkin_time
  end

  def checkin_folder_id
    nil
  end

  def insert(group_time, placement = :top)
    sequence = if placement == :top
                 0
               else
                 group_times.length + 1
               end
    group_time.update_attributes(checkin_folder: self, checkin_time: nil, sequence: sequence)
    resequence
  end
end
