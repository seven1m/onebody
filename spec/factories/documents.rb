FactoryGirl.define do
  factory :document do
    name 'Test Document'
    description 'document description'

    trait :with_fake_file do
      file_file_name 'dummy'
    end
  end
end
