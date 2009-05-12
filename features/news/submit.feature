Feature: Users Submit News
  In order to share news and information
  As a user
  I want to submit news
  
  Background:
    Given setting "News Page" in category "Features" is enabled
    And setting "News by Users" in category "Features" is enabled
    And I am signed in as a user
  
  Scenario: User sees no news when there are no posts
    Given there are no news items
    When I go to news
    Then I should see "No news is available at this time."
  
  Scenario: User sees news when there is a post
    Given there is a news item with title "A News Post" and body "This is the first news post."
    When I go to news
    Then I should see "A News Post"
    And I should see "This is the first news post."
  
  Scenario: User submits news
    When I go to new news submission
    And I fill in "Give your post a concise title" with "My News Item"
    And I fill in "Share your announcement, information, or news here" with "This is my first news post."
    And I press "Submit News"
    Then I should see "Your news has been submitted."
    When I go to news
    Then I should see "My News Item"
    And I should see "This is my first news post."
  
  # Scenario: User edit items they have submitted