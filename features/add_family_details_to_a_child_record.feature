Feature: Add family details

  Scenario: Storing family names
    Given I am logged in
    Given I am on the new child page

    When I fill in the basic details of a child
    And I fill in "Mary" for "Mother's name"
    And I press "Save"

    Then I should see "Mary"
