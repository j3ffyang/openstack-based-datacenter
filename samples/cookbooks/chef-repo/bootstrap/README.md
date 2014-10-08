For production-gemini.erb
=========

About bootstrap is a process that installs the chef-client on a target system so that it can run as a chef-client and communicate with a server.

  - For Gemini we need use bootstrap to prepare services packages or require environment.

Precondition environment variable.
--------------

```sh
# Provider your macthine ip address, for example:
export IP_ADDR="172.16.27.6"

# Setup internal public authorized keys access.
export AUTHORIZED_KEYS=`cat /root/.ssh/id_rsa.pub`

# Set admin key to other client nodes.
export CLIENT_KEY=`cat /etc/chef/admin.pem`
```

##### You need to run on the chef-server node.

How to run bootstrap ?
--------------

##### For example :

```sh
knife bootstrap $IP -d $ENV -x $USER -P $PASSWORD
```

$IP: Install machine ip address.

$ENV: Set the Chef environment.

$USER: The ssh username.

$PASSWORD: The ssh password.

  - You can use above description to setup openstack conpoments.
