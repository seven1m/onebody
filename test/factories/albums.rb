FactoryGirl.define do
  factory :album do
    sequence(:name) { |n| "Album #{n}" }
  end
end
