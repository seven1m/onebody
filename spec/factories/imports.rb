FactoryGirl.define do
  factory :import do
    person
    filename        'foo.csv'
    importable_type 'Person'
    status          'pending'
    mappings('first' => 'first_name', 'last' => 'last_name')
  end
end
