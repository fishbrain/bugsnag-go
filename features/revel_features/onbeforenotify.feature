Feature: Configuring on before notify

Background:
  Given I set environment variable "API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I configure the bugsnag endpoint
  And I set environment variable "SERVER_PORT" to "4515"
  And I set environment variable "AUTO_CAPTURE_SESSIONS" to "false"
  And I set environment variable "USE_CODE_CONFIG" to "true"

Scenario Outline: Send three bugsnags and use on before notify to drop one and modify the message of another
  Given I set environment variable "REVEL_VERSION" to "<revel version>"
  And I set environment variable "REVEL_CMD_VERSION" to "<revel cmd>"
  When I start the service "revel"
  And I wait for the app to open port "4515"
  And I wait for 4 seconds
  And I open the URL "http://localhost:4515/onbeforenotify"
  Then I wait to receive 2 requests
  
  And the request 0 is a valid error report with api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the exception "message" equals "Don't ignore this error" for request 0
  
  And the request 1 is a valid error report with api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the exception "message" equals "Error message was changed" for request 1

  Examples:
  | revel version | revel cmd |
  | v0.21.0       | v0.21.1   |
  | v0.20.0       | v0.20.2   |
  | v0.19.1       | v0.19.0   |
  | v0.18.0       | v0.18.0   |
  