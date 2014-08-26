## Install OpenVPN
	[root@r83x5u09 yum.repos.d]# yum install openvpn easy-rsa

## Create Configuration Files
	mkdir -p /etc/openvpn/easy-rsa/
	cp -rf /usr/share/easy-rsa/2.0/* /etc/openvpn/easy-rsa/
	cp /etc/openvpn/easy-rsa/openssl-1.0.0.cnf /etc/openvpn/easy-rsa/openssl.cnf

## Create Credential
	[root@r83x6u05 easy-rsa]# pwd
	/etc/openvpn/easy-rsa
	[root@r83x6u05 easy-rsa]# source ./vars
	./clean-all
	./build-ca
	./build-dh
	./build-key-server server
	./build-key client
	cd keys
	cp dh2048.pem ca.crt server.crt server.key /etc/openvpn/

## Create Server Configuration for Management Network (172.16.0.0/16)
	cp /usr/share/doc/openvpn-2.3.2/sample/sample-config-files/server.conf /etc/openvpn/mgmt.conf

## Sample Configuration File for Management Network (172.16.0.0/16)
	...
	port 1194
	proto udp

	ca ca.crt
	cert server.crt
	key server.key  # This file should be kept secret
	dh dh1024.pem

	;server 10.8.0.0 255.255.255.0

	;server-bridge 10.8.0.4 255.255.255.0 10.8.0.50 10.8.0.100
	server-bridge 172.16.0.21 255.255.0.0 172.16.0.241 172.16.0.244

	;server-bridge

	duplicate-cn
	keepalive 10 120

	comp-lzo

