## Download OpenStack Enterprise Edition then Extract

## Upload Cookbooks

	cd /opt/mabo/IBM_Cloud_Orchestrator-2.4.0.0-D20140918-041640/data/openstack/chef-repo/cookbooks
	knife cookbook upload -a -o ./

## Upload Roles

	cd ../roles
	for i in `ls *.json`; do knife role from file $i; done

## Get Gemini Cookbooks
	
	cd /opt/git/gemini; git pull
