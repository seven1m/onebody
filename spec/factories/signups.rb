FactoryGirl.define do
  factory :signup do
    email 'john@example.com'
    first_name 'John'
    last_name 'Smith'
    gender 'Male'
    birthday '1980-01-01'
    mobile_phone '1234567890'
  end
end
