FactoryGirl.define do
  factory :prayer_request do
    request 'my health'
    answer  'healthy!'
    answered_at Time.now
    person
    group
  end
end
