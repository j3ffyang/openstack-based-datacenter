#!/bin/bash
#This script is used to deploy galera with following tasks:
#   
#   modified cookbook from git
#   add new added role
#   upload databag
#   use chef to deploy

#clone the repo, driven by jenkins
#git clone http://github.rtp.raleigh.ibm.com/chef-toolkit/gemini.git



#manually modify the ~/.chef/knife.rb
if ! grep "cookbook_path" ~/.chef/knife.rb > /dev/null 2>&1 ; then
   echo "cookbook_path ['.']" >> ~/.chef/knife.rb    
fi

#update the chef-repo
cd ../chef-repo/cookbooks
knife cookbook upload galera
knife cookbook upload haproxy
knife cookbook upload cpu
knife cookbook upload keepalived
knife cookbook upload yum
knife cookbook upload mysql
knife cookbook upload openstack-identity

cd ../
knife data bag delete gemini -y
knife data bag create gemini
knife data bag from  file gemini data_bags/gemini/config.json 

knife role delete gemini-controller -y
knife role from file roles/gemini-controller.json
knife role delete gemini-controller1 -y
knife role from file roles/gemini-controller1.json
knife role delete gemini-controller2 -y
knife role from file roles/gemini-controller2.json
knife role delete gemini-controller3 -y
knife role from file roles/gemini-controller3.json

knife environment delete gemini -y
knife environment from file environments/gemini.json

export HTTP_REPO_PORT=3080
knife client delete ctrlr0 -y
knife bootstrap 172.16.0.33 -c /etc/chef/knife.rb -u root -P passw0rd -N ctrlr0 --template-file ../erb/gemini.erb -r 'role[gemini-controller1]' -E gemini
knife client delete ctrlr1 -y
knife bootstrap 172.16.0.34 -c /etc/chef/knife.rb -u root -P passw0rd -N ctrlr1 --template-file ../erb/gemini.erb -r 'role[gemini-controller2]' -E gemini
knife client delete ctrlr2 -y
knife bootstrap 172.16.0.35 -c /etc/chef/knife.rb -u root -P passw0rd -N ctrlr2 --template-file ../erb/gemini.erb -r 'role[gemini-controller3]' -E gemini
