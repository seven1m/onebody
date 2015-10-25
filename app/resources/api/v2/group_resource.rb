module Api
  module V2
    class GroupResource < OneBodyResource
      attributes :name, :description, :meets, :location, :directions,
                 :other_notes, :category, :private, :address,
                 :latitude, :longitude, :site_id, :legacy_id

      has_many :people
      has_many :admins
      # has_many :messages
      # has_many :prayer_requests
      # has_many :attendance_records
      # has_many :stream_items
      # has_many :attachments
      # has_many :group_times
      # has_many :checkin_times
      # has_many :tasks
      has_one :creator, class_name: 'Person'
      has_one :leader, class_name: 'Person'
    end
  end
end