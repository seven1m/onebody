Feature: Users Submit News
  In order to share news and information
  As a user
  I want to submit news
  
  Background:
    Given I am signed in as a user
  
  Scenario: User sees no news when there are no submissions
    Given there are no news items
    When I go to news
    Then I should see "No news is available at this time."
  
  Scenario: User sees news when there is a submission
    Given there is a news item with title "A News Post" and body "This is the first news post."
    When I go to news
    Then I should see "A News Post"
    And I should see "This is the first news post."
  
  Scenario: User submit news
    When I go to new news submission
    Then I should see "Title"
    And I should see "Body"
    When I fill in "Title" with "My News Item"
    And I fill in "Body" with "This is my first news post."
    And I press "Submit News"
    Then I should see "Your news post has been submitted."
  
  # Scenario: User edit items they have submitted