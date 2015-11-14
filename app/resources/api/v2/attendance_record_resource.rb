module Api
  module V2
    class AttendanceRecordResource < OneBodyResource
      attributes :first_name, :last_name, :family_name, :age, :can_pick_up,
                 :cannot_pick_up, :medical_notes, :print_extra_nametag,
                 :attended_at

      has_one :person
      has_one :group
      has_one :checkin_time
    end
  end
end