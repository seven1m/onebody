FactoryGirl.define do
  factory :message do
    person
    sequence(:subject) { |n| "Message #{n}" }
    body 'this is the message body'
  end
end
