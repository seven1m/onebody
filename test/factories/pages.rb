FactoryGirl.define do
  factory :page do
    sequence(:slug) { |n| "page_#{n}" }
    sequence(:path) { |n| "page_#{n}" }
    title 'Page'
    body 'this is the page body'
  end
end
