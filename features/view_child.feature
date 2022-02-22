Feature: Playing audio files uploaded to child records
	@wip
	Scenario: Viewing a child record with audio attached
		Given I am logged in
		And a child record named "Fred" exists with a audio file with the name "sample.mp3"
		When I am on the child record page for "Fred"
		Then I should see an audio element that can play the audio file named "sample.mp3"
	