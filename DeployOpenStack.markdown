## Deploying OpenStack is done with previous steps

## Create Image

	glance --debug image-create --name cirros-0.3.1-raw-rbd --disk-format raw --container-format bare --is-public True < ~/cirros-0.3.1-raw-rbd
