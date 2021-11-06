Feature:
  So that changes to the child record are kept for historical purposed and can be viewed

Scenario: Creates a child record and checks the log

  Given "Harry" is logged in
	And no children exist
	And I am on the children listing page
	And I follow "New child"
	When I fill in "Jorge Just" for "Name"
	And I fill in "27" for "Age"
	And I select "Exact" from "Age is"
	And I choose "Male"
	And I fill in "London" for "Origin"
	And I fill in "Haiti" for "Last known location"
	And I select "1-2 weeks ago" from "Date of separation"
	And I attach the file "features/resources/jorge.jpg" to "photo"
	And the date/time is "July 19 2010 13:05"
	And I press "Finish"

	When I follow "View the change log"
	Then I should see "19/07/2010 13:05 Record created by Harry"
