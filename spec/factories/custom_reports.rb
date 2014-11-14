FactoryGirl.define do
  factory :custom_report do
    sequence(:title) { |n| "Test Custom Report#{n}" }
    category '1'
    sequence(:body) { |n| "This is the #{n}th Custom Report. {{#person}}{{first_name}} {{last_name}}{{/person}}" }
    filters 'gender:Male'
  end
end
