Feature: Plain handled errors

Background:
  Given I set environment variable "API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I configure the bugsnag endpoint
  And I set environment variable "SERVER_PORT" to "4513"

Scenario: A handled error sends a report
  When I start the service "martini"
  And I wait for the app to open port "4513"
  And I wait for 2 seconds
  And I open the URL "http://localhost:4513/handled"
  Then I wait to receive 2 requests
  And the request 0 is a valid error report with api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the request 1 is a valid session report with api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "unhandled" is false for request 0
  And the event "severity" equals "warning" for request 0
  And the event "severityReason.type" equals "handledError" for request 0
  And the exception "errorClass" equals "*os.PathError" for request 0
  And the "file" of stack frame 0 equals "main.go" for request 0
  And the event handled sessions count equals 1 for request 0
  And the number of sessions started equals 1 for request 1
  