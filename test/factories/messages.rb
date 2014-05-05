FactoryGirl.define do
  factory :message do
    person
    sequence(:subject) { |n| "Message #{n}" }
    body 'this is the message body'

    trait :with_attachment do
      after(:create) do |m|
        m.attachments.create!
      end
    end
  end
end
