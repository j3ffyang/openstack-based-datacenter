#!/usr/bin/python
#**********************************************
#*                                            *
#*   LICENSED MATERIALS - PROPERTY OF IBM     *
#*   COPYRIGHT IBM CORP. 2013                 *
#*   Authors: Kai Flohr, Andreas Schmitt      *
#                                             *
#**********************************************
#
import sys
import logging
import xml.etree.ElementTree as xml
import os as os
import zipfile as zipfile
import subprocess
from subprocess import call
from datetime import datetime
from optparse import OptionParser
from array import *
import shutil
import shlex
import time
import socket
import re
import getpass

# Switch on debug statements
DEBUG = 0

# User which is used to execute remote commands
SSH_USER = "root"

# Version
VERSION = "1.0.2"

# ANSI codes needed for logging
bold = "\033[1m"
red = "\033[31m"
green = "\033[32m"
blue = "\033[34m"
reset = "\033[0;0m"

# Return codes of start/stop scripts
ONLINE  = 1<<8
OFFLINE = 2<<8

systemName = socket.gethostname()
scriptDir = os.path.dirname(os.path.realpath(__file__)) + '/'

###############################################
# getSSHArg		                      #
###############################################
def getSSHArg():
	args_str = " -o StrictHostKeyChecking=no "
	smartcloud_ssh_key_path = "/root/.ssh/smartcloud"
	if os.path.isfile(smartcloud_ssh_key_path):
		args_str = " -o StrictHostKeyChecking=no -i /root/.ssh/smartcloud "
	return args_str

###############################################
# readComponents		                      #
###############################################
def readComponents(fileName):
	componentDataContainer = {}
	try:
		tree = xml.parse(fileName)
		rootElement = tree.getroot()
		componentList = rootElement.findall("component")
		if componentList != None:
			for component in componentList:
				if "name" in component.attrib:
					componentName = component.attrib["name"]
					componentDataContainer[componentName]= component.attrib
	except Exception, e:
		logger.error("ERROR: reading and parsing componentfile Error details: '{0}'".format(e) + fileName)
	return componentDataContainer

###############################################
# readEnvironment		                      #
###############################################
def readEnvironment(fileName, componentDataContainer):
	resourceList = []
	try:
		tree = xml.parse(fileName)
		rootElement = tree.getroot()
		hostList = rootElement.findall("host")
		for host in hostList:
			if "hostname" in host.attrib:
				hostname = host.attrib['hostname']
				# Bypass CS4_IP for product SCP
				if hostname == "CS4_IP":
					continue
				componentList = host.findall("component");
				for component in componentList:
					if "name" in component.attrib:
						componentName = component.attrib['name']
						if componentName in componentDataContainer:
							componentAttributes = componentDataContainer[componentName]
							resource = {"hostname": hostname}
							for key in componentAttributes:
								resource[key] = componentAttributes[key]
							resourceList.append(resource)
	except Exception, e:
		logger.error("ERROR: reading and parsing environmentfile Error details: '{0}'".format(e) + fileName)
	return resourceList

###############################################
# refreshEnvironmentFile                      #
###############################################
def refreshEnvironmentFile(fileName):
	novaComponentList = []
	# Retrieve compute nodes
	try:
		logger.debug("Retrieving compute nodes")
		logger.debug("Running '. ~/openrc >/dev/null 2>&1 || . ~/keystonerc >/dev/null 2>&1 && nova hypervisor-list' command")
		novaComponentList = []
		file = os.popen('. ~/openrc >/dev/null 2>&1|| . ~/keystonerc >/dev/null 2>&1&& nova hypervisor-list')
		lines = []
		if file is not None:
			lines = file.readlines()
			for line in lines:
				if "failed" not in line:
					novaComponentList.append(line)
		file.close()
	except Exception, e:
		logger.error("Error retrieving compute nodes. Error details: '{0}'".format(e))

	computeNodeMap = {}
	for line in novaComponentList:
		parts = line.split("|")
		if len(parts) > 1:
			if not re.search('Hypervisor hostname', parts[2]):
				hostname = parts[2]
				if "@" in hostname:
					# Special treatment for VMWare hostnames
					# virtual server format: xvm241.boeblingen.de.ibm.com@10.102.100.196-443
					computeNodeParts = hostname.split("@")

					# ESX node
					esxComputeNode = computeNodeParts[0]
					computeNodeMap[esxComputeNode] = "esxnode"

					# VM node
					if len(computeNodeParts) > 1:
						computeNodeParts = computeNodeParts[1].split("-")
						vmComputeNode = computeNodeParts[0]
						computeNodeMap[vmComputeNode] = "vmnode"
				else:
					# Ordinary hostname
					if hostname != systemName:
						computeNodeMap[hostname] = "computenode"

	logger.debug("Compute node mapping: {0}".format(computeNodeMap))

	# Add retrieved compute nodes to environment file
	logger.debug("Adding compute nodes to environment file: {0}".format(fileName))
	return appendComputeNodesToEnvironmentFile(fileName, computeNodeMap)

###############################################
# transferScriptToRemoteSystem                #
###############################################
def transferScriptToRemoteSystem(scriptName, hostname, workdir):
	try:
		command = "scp"
		toDir =  SSH_USER + "@" + hostname + ":" + workdir
		if '/' not in scriptName:
			scriptName = scriptDir + scriptName
		os.system(command + ssh_arg_str + " -q '" + scriptName + "'  '" + toDir + "'")
		logger.debug("Transfered script file " + scriptName + " to host " + hostname + " into directory " + workdir)
	except:
		logger.error("ERROR: transfering file " + scriptName + " to host " + hostname)

###############################################
# makeScriptExecuteable                       #
###############################################
def makeScriptExecuteable(hostname, scriptName, workdir):
	try:
		host = SSH_USER + "@" + hostname
		cmd = "cd " + workdir + "; chmod +x " + scriptName
		logger.debug("Executing command '{0}' on host {1}".format(cmd, hostname))
		os.system("ssh" + ssh_arg_str + " " + host + " '" + cmd + "'")
	except:
		logger.error("ERROR: making script " + scriptName + " executable at host " + hostname)

###############################################
# deleteScriptFilefromRemoteHost              #
###############################################
def deleteScriptFilefromRemoteHost(hostname, filename):
	try:
		command = "ssh"
		cmd = "[[ -e " + filename + " ]] && rm " + filename
		host = SSH_USER + "@" + hostname
		rc =  os.system(command + ssh_arg_str + " " + host + " '" + cmd + "'")
		if rc == 1:
			logger.error("Nothing to clean for remote file " + filename + " at host " + hostname)
		elif rc == 0:
			logger.debug("Cleaned remote file " + filename + " from host " + hostname)
	except:
		logger.error("ERROR: Cleaning remote file " + filename + " at host " + hostname)

###############################################
# appendComputeNodesToEnvironmentFile         #
###############################################
def appendComputeNodesToEnvironmentFile(fileName, computeNodeMap):
	workfilename = fileName
	if workfilename.endswith(".xml"):
		workfilename = workfilename[:-4]
	workfilename += "_work.xml"
	try:
		envFile = open(fileName, 'r')
		envXml = envFile.read()
		envFile.close()
		envTree = xml.fromstring(envXml)

		for computeNode in computeNodeMap:
			if computeNodeMap[computeNode] == "computenode":
				computeNodeElements = "<host hostname=\"" + computeNode + "\">\n"
				computeNodeElements += "\t<component name=\"openstack-nova-network\"/>\n"
				computeNodeElements += "\t<component name=\"openstack-nova-compute\"/>\n"
				computeNodeElements += "\t<component name=\"openstack-metadata-api\"/>\n"
				computeNodeElements += "\t<component name=\"openstack-novncproxy\"/>\n"
				computeNodeElements += "\t</host>"
				computeNodeTree = xml.fromstring(computeNodeElements)
				envTree.append(computeNodeTree)

		outFile = open(workfilename, 'w')
		outFile.write(xml.tostring(envTree))
		outFile.close()
	except Exception, e:
		logger.error("Error appending compute nodes to environment file: '{0}'. Error details: '{1}'".format(fileName, e))
	return workfilename

###############################################
# executeCommandOnRemoteSystem                #
###############################################
def executeCommandOnRemoteSystem(hostname, command, workdir):
	rc = 0
	try:
		host = SSH_USER + "@" + hostname
		if DEBUG == 0:
			cmd = "cd " + workdir + ";" + command + " >/dev/null 2>/dev/null"
		else:
			cmd = "cd " + workdir + ";" + command
		logger.debug("Executing command '{0}' on host {1}".format(cmd, hostname))
		rc = os.system("ssh" + ssh_arg_str + " " + host + " '" + cmd + "'")
	except:
		logger.error("ERROR: executing command on remote system for command " + command + " at host " + hostname)
		rc = 42
	return rc

###############################################
# matchComponent		                      #
###############################################
def matchComponent(componentName, componentList):
	for component in componentList:
		try:
			pattern = re.compile(component)
			match = pattern.match(componentName)
			if match is not None:
				return True
		except:
			logger.error("ERROR: matching components or pattern corrupt.")
	return False

###############################################
# processCommandList		                  #
###############################################
def processCommandList(resourceList, action, systemList, componentList):
	if action == "status":
		print "Component" + 21 * " " + "Hostname " + 21 * " " + "Status"
		print 66 * "-"

	# Filter resources if systemList and/or componentList are specified
	resourceworkList = []
	if (systemList is not None and len(systemList) > 0 and systemList[0] != 'none') or (componentList is not None and len(componentList) > 0 and componentList[0] != 'none'):
		for resource in resourceList:
			hostname = resource["hostname"]
			componentName = resource["name"]
			if hostname in systemList:
				resourceworkList.append(resource)
			elif componentName in componentList or matchComponent(componentName,componentList):
				resourceworkList.append(resource)
		if (resourceworkList is not None and len(resourceworkList) > 0):
			resourceList = resourceworkList
		else:
			print red + bold + "Resource not in resource list nothing to process. Processing done. Check input." + reset
			exit(1)
	try:
		for resource in resourceList:
			hostname = resource["hostname"]
			workdir = resource["workdir"]
			scriptName = resource["scriptName"]
			resourceName = resource["name"]
			# Transfer script to target system
			transferScriptToRemoteSystem(scriptName, hostname, workdir)

			# Make script executable
			makeScriptExecuteable(hostname, scriptName, workdir)
			if action == "start":
				logger.info("starting " + resourceName + " ...")
			elif action == "stop":
				logger.info("stopping " + resourceName + " ...")

			# Execute script on remote system and wait for return code
			# Ask for credentials if specified in Components.xml
			if "promptCredentials" in resource and action in resource["promptCredentials"]:
				user = ""
				pw = ""
				(user, pw) = getUseridAndPasswd()
				command = "./" + scriptName + " " + action + " " + user + " " + pw
			elif "openstackService" in resource:
				command = "./" + scriptName + " " + resourceName + " " + action
			else:
				command = "./" + scriptName + " " + action

			rc = executeCommandOnRemoteSystem(hostname, command, workdir)

			if action == "start":
				if rc == 0:
					logger.info(resourceName + " started")
				else:
					logger.info ( resourceName + " could not be started")
					exit(1)
			elif action == "stop":
				if rc == 0:
					logger.info(resourceName + " stopped")
				else:
					logger.info(resourceName + " could not be stopped")
			elif action == "status":
				if rc == ONLINE:
					resource["status"] = "online"
					displayStatus(resourceName, hostname, resource["status"], green)
				elif rc == OFFLINE:
					resource["status"] = "offline"
					displayStatus(resourceName, hostname, resource["status"], red)
				else:
					resource["status"] = "unknown"
					displayStatus(resourceName, hostname, resource["status"], blue)

			# Clean up transfered script
			deleteScriptFilefromRemoteHost(hostname, os.path.join(workdir,scriptName))
	except Exception,e:
		logger.error("Error processing resourceList: '{0}'. Error details: '{1}'".format(resourceList, e))
		exit(1)

###############################################
# displayStatus                               #
###############################################
def	displayStatus(resourceName, hostname, status, color):
	# Fill name up to 30 characters
	if resourceName is not None and len(resourceName) < 30:
		resourceName = resourceName + (30 - len(resourceName)) * " "
	if hostname is not None and len(hostname) < 30:
		hostname = hostname + (30 - len(hostname)) * " "

	print resourceName + hostname + color + status + reset

###############################################
# parseInputParameter                         #
###############################################
def parseInputParameter():
	parser = OptionParser()
	parser.add_option("-s", "--start", action="store_true", dest="start",
					  help="start SC Orchestrator with default parameters in default sequence")
	parser.add_option("--halt", "--shutdown", "--stop" , action="store_true", dest="stop",
					  help="stops SC Orchestrator in default sequence")
  	parser.add_option("--status", action="store_true", dest="status",
					  help="status of components of SC Orchestrator")
	parser.add_option("-c", "--componentfile", dest="ComponentFilename", default=scriptDir + "SCOComponents.xml",
					  help="defines the input properties filename, default: file SCOComponents.xml in script directory", metavar="SCOComponents.xml")
	parser.add_option("-e", "--environmentfile", dest="EnvironmentFilename", default=scriptDir + "SCOEnvironment.xml",
					  help="defines the environment filename, default: file SCOEnvironment.xml in script directory", metavar="SCOEnvironment.xml")
	parser.add_option("-n", "--hostnames",
					  action="store", type="string", dest="systemslist", default="none",
					  help="list of hostnames to start/stop format hostname1,hostname2,hostname3,...")
	parser.add_option("-p", "--components",
					  action="store", type="string", dest="componentslist", default="none",
					  help="list of components to start/stop format component1,component2,component3,...")
	parser.add_option("--version",
					  action="store_true", dest="showversion",
					  help="show version")
	return parser.parse_args()

###############################################
# Setup logger                                #
###############################################
# Define the logger parameter and formats
SCOrchestratorLogFileName = scriptDir + "SCOrchestrator.log"
logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s %(levelname)-8s %(message)s',
                    datefmt='%a, %d %b %Y %H:%M:%S',
                    filename=SCOrchestratorLogFileName,
                    filemode='w')
logger = logging.getLogger('SCOrchestrator')
# Add additional log handler for SystemOut logging
ch = logging.StreamHandler()
ch.setLevel(logging.INFO)
logger.addHandler(ch)

logger.debug("SCOrchestrator version: {0}".format(VERSION))

###############################################
# getUseridAndPasswd                          #
###############################################
def getUseridAndPasswd():
	user = raw_input("Enter Username: ")
	pw = getpass.getpass()
	return user,pw


###############################################
# Main                                        #
###############################################
if __name__ == '__main__':
	# Get the input parameter and parse them for processing
	(options, args) = parseInputParameter()
	if not(options.start == True or options.stop == True or options.status == True):
		if len(args) == 0:
			options.status = True
		elif len(args) != 0 and args[0] == "start":
			options.start = True
		elif len(args) != 0 and args[0] == "stop":
			options.stop = True
		elif len(args) != 0 and args[0] == "status":
			options.status = True
		elif len(args) > 1:
			print red + bold + "Too many arguments in commandline, respecify command, SCOrchestator.py -h for help." + reset
			exit(1)
		else:
			print red + bold + "Error in commandline, respecify command, SCOrchestator.py -h for help." + reset
			exit(1)
	# Log the input parameters
	logger.debug("Components in : " + options.ComponentFilename)
	logger.debug("Environment in : " + options.EnvironmentFilename)
	logger.debug("Optional hostnamelist: " + options.systemslist)
	logger.debug("Optional componentlist: " + options.componentslist)

	ssh_arg_str = getSSHArg()
	logger.debug(ssh_arg_str)
	componentFileName = options.ComponentFilename
	environmentFileName = options.EnvironmentFilename
	systemList = options.systemslist.replace(" ","").split(",")
	componentList = options.componentslist.replace(" ","").split(",")
	showVersion = options.showversion
	start = options.start
	stop = options.stop
	status = options.status

	# Show SCOrchestrator version
	if showVersion:
		print "SCOrchestrator version: {0}".format(VERSION)
		exit(0)

	# Read component.xml
	components = readComponents(componentFileName)

	# Enhance the Environment file with the compute nodes that are available
	# Do not refresh compute nodes on start.  Only use existing work file if it exists
	if not start:
		environmentWorkFileName = refreshEnvironmentFile(environmentFileName)
	else:
		if environmentFileName.endswith(".xml"):
			environmentWorkFileName = environmentFileName[:-4]
			environmentWorkFileName += "_work.xml"
			if not os.path.isfile(environmentWorkFileName):
				environmentWorkFileName = environmentFileName

	# Read environment.xml and create list of resources (components)
	resourceList = readEnvironment(environmentWorkFileName, components)

	if start:
		logger.info(green + "===>>> Starting Smart Cloud Orchestrator" + reset)
		# Sort list according to start priority
		startList = sorted(resourceList, key=lambda prio: int(prio["startPrio"]))

		# Start components
		processCommandList(startList,"start", systemList, componentList)
		logger.info(green + "===>>> Starting Smart Cloud Orchestrator complete" + reset)
	elif stop:
		logger.info(green + "===>>> Stopping Smart Cloud Orchestrator" + reset)
		# Sort list according to stop priority
		stopList = sorted(resourceList, key=lambda prio: int(prio["stopPrio"]))

		# Stop components
		processCommandList(stopList,"stop", systemList, componentList)
		logger.info(green + "===>>> Stopping Smart Cloud Orchestrator complete" + reset)
	elif status:
		logger.info(green + "===>>> Collecting Status for Smart Cloud Orchestrator" + reset)
		logger.info(green + "===>>> Please wait ======>>>>>>" + reset)
		logger.info("")

		# Sort list by name
		statusList = sorted(resourceList, key=lambda prio: prio["name"])

		# Collect status information for components
		processCommandList(statusList,"status", systemList, componentList)
		logger.info("")
		logger.info(green + "===>>> Status Smart Cloud Orchestrator complete" + reset)

