# language: en
Feature: Gemini self-service

  As a self-service user
  I want to use cloud resource

  Scenario: End user portal
    Given a URL https://gemini.cdl.ibm.com/
    Then I can log in with IBM w3 id

  Scenario: FQDN for VMs
    Given a launched VM
    Then I can access it over a resolvable FQDN like `foo.gemini.cdl.ibm.com`

  Scenario: vmx flag inside VM
    Given a launched VM
    Then it supports flag vmx from VM cpu.

  Scenario: private network among VMs
    Given OpenStack API
    When I create a private network
    Then I can launch VMs which can connect to each other with this private network

