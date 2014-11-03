## Build an HTTP

We're going to register all image through HTTP. Therefore, we'd need to choose r83x5u08 to build an HTTP Apache server first.

	yum install httpd -y
	systemctl enable httpd.service
	systemctl start httpd.service
