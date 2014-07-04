FactoryGirl.define do
  factory :checkin_time do
    campus 'Broken Arrow'

    trait :recurring do
      weekday 0
      time '9:00 am'
    end
  end
end
