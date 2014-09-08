FactoryGirl.define do
  factory :task do
    sequence(:name) { |n| "Task #{n}" }
    sequence(:description) { |n| "Description for task #{n}" }
    completed false
    duedate Date.today
    person
    group
  end
end
