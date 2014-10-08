# Overview

Scripts under `lib/scorchestrator` in this project is to start, stop and provide status of SCO services, more information can be found from [infocenter](http://eden1.tivlab.austin.ibm.com:8310/help/index.jsp?topic=%2Fcom.ibm.sco.doc_2.3%2Fc_startstop_tool.html)

The following three files are customized for Gemini, and all other files under `lib/scorchestrator` are from SCO 2.3.0.1 GA packages
* GeminiComponents.xml  -- Defines components in Gemini
* GeminiEnvironment.xml -- Defines deployment topology in Gemini, should be updated when there's any changes in hostname, topo, etc
* README.md             -- This readme file

* Requirements and usage
 * `SCOrchestrator.py` should be run on any servers in overcloud, otherwise, the won't get correct compute node information
 * SSH key file should be named `/root/.ssh/smartcloud` in the server where `SCOrchestrator.py` runs, and should be able to access all other nodes using this key passwordlessly. 
