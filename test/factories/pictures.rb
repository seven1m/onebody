FactoryGirl.define do
  factory :picture do
    album
    after(:build) do |pic|
      pic.photo = File.open(Rails.root.join('test/fixtures/files/image.jpg'))
    end
  end
end
