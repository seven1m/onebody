class GroupTime < ApplicationRecord
  belongs_to :group
  belongs_to :checkin_folder
  belongs_to :checkin_time

  default_scope -> { order(:sequence) }

  scope_by_site_id

  before_create { parent&.update_sequence(self) }

  def parent
    checkin_folder || checkin_time
  end

  def time
    checkin_time || checkin_folder.try(:checkin_time)
  end

  def remove_from_checkin_folder(placement = :above)
    cf = checkin_folder
    self.checkin_time = checkin_folder.checkin_time
    self.sequence = cf.sequence + (placement == :above ? 0 : 1)
    self.checkin_folder = nil
    checkin_time.entries.select { |e| e.sequence >= sequence }.each_with_index do |gt, index|
      gt.update_attribute(:sequence, sequence + index + 1)
    end
    save
    checkin_time.reload
    cf.resequence
  end
end
