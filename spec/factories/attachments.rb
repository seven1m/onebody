FactoryGirl.define do
  factory :attachment do
    sequence(:name) { |n| "Attachment #{n}" }
  end
end