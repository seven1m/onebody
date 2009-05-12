Given /^there are no news items$/ do
end

Given /^there is a news item with title "([^\"]*)" and body "([^\"]*)"$/ do |title, body|
  NewsItem.create!(
    :title => title,
    :body  => body
  )
end