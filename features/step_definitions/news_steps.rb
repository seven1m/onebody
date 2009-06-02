Given /^there are no news items$/ do
end

Given /^there is a news item with title "([^\"]*)" and body "([^\"]*)"$/ do |title, body|
  NewsItem.create!(
    :title => title,
    :body  => body
  )
end

When /^I click "([^\"]*)" on the news item "([^\"]*)"$/ do |link, title|
 response.should have_selector(".news-item a")
 click_link_within(".news-item[:first]", "edit")
end

