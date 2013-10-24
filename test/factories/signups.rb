FactoryGirl.define do
  factory :signup do
    email 'john@example.com'
    first_name 'John'
    last_name 'Smith'
    gender 'Male'
    birthday '1980-01-01'
  end
end
