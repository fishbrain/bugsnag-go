Feature: Using auto notify

Background:
  Given I set environment variable "API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I configure the bugsnag endpoint
  And I set environment variable "SERVER_PORT" to "4515"
  And I set environment variable "USE_CODE_CONFIG" to "true"
  
Scenario Outline: An error report is sent when an unhandled crash occurs
  Given I set environment variable "REVEL_VERSION" to "<revel version>"
  And I set environment variable "REVEL_CMD_VERSION" to "<revel cmd>"
  And I set environment variable "AUTO_CAPTURE_SESSIONS" to "false"
  When I start the service "revel"
  And I wait for the app to open port "4515"
  And I wait for 4 seconds
  And I open the URL "http://localhost:4515/unhandled"
  Then I wait to receive a request
  And the request is a valid error report with api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "unhandled" is true 
  And the exception "errorClass" equals "*runtime.TypeAssertionError"
  And the exception "message" matches "interface conversion: interface ({} )?is struct {}, not string"

  Examples:
  | revel version | revel cmd |
  | v0.21.0       | v0.21.1   |
  | v0.20.0       | v0.20.2   |
  | v0.19.1       | v0.19.0   |
  | v0.18.0       | v0.18.0   |

Scenario Outline: An error report is sent when a go routine crashes which is protected by auto notify
  Given I set environment variable "REVEL_VERSION" to "<revel version>"
  And I set environment variable "REVEL_CMD_VERSION" to "<revel cmd>"
  When I start the service "revel"
  And I wait for the app to open port "4515"
  And I wait for 4 seconds
  And I open the URL "http://localhost:4515/autonotify"
  And I wait for 3 seconds
  # Then I wait to receive 3 requests
  And the request 0 is a valid error report with api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the request 1 is a valid session report with api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  # And the request 2 is a valid error report with api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "unhandled" is true for request 0
  And the exception "errorClass" equals "*errors.errorString" for request 0
  And the exception "message" equals "Go routine killed with auto notify" for request 0
  # And the event "unhandled" is true for request 2
  # And the exception "errorClass" equals "panic" for request 2
  # And the exception "message" equals "Go routine killed with auto notify [recovered]" for request 2
  And the event unhandled sessions count equals 1 for request 0
  And the number of sessions started equals 1 for request 1

  Examples:
  | revel version | revel cmd |
  | v0.21.0       | v0.21.1   |
  | v0.20.0       | v0.20.2   |
  | v0.19.1       | v0.19.0   |
  | v0.18.0       | v0.18.0   |