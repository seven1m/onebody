FactoryGirl.define do
  factory :page do
    sequence(:slug) { |n| "page_#{n}" }
    title 'Page'
    body 'this is the page body'
    system true
  end
end
