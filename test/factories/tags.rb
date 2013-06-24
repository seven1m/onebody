FactoryGirl.define do
  factory :tag do
    sequence(:name) { |n| "Tag #{n}" }
  end
end
