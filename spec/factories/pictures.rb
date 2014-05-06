FactoryGirl.define do
  factory :picture do
    album

    trait :with_file do
      after(:build) do |pic|
        pic.photo = File.open(Rails.root.join('spec/fixtures/files/image.jpg'))
      end
    end
  end
end
