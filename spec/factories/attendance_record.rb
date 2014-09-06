FactoryGirl.define do
  factory :attendance_record do
    association :person
    association :group
    attended_at Time.now
  end
end
