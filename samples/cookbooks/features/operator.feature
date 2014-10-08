# language: en
Feature: Gemini operation

  As an operator
  I want to install latest SCO product
  So that I can host services provided by latest product features

  Scenario: IMM and Management networking connectivity
    Given IMM IP list file "conf/gemini-imm.lst"
    Then I access to all IMM addr
    Then I access to all management addr "conf/gemini-mgt.lst"

  Scenario: Baremetal Provisioning
    Given network connected baremental machines
    When I install RHEL OS over PXE
    Then I can adjust public key over kickstart file

  Scenario: Administration portal
  	Given a URL https://gemini.cdl.ibm.com/dashboard/
  	Then I can log in with IBM w3 id

  Scenario: OpenStack API
    Given a URL https://gemini.cdl.ibm.com/distillery/
    Then I can get a report of working features
