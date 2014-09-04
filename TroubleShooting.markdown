## Known Issues

### r83x5u09 machine reboot unexpectedly at 4.11am every day    
Update /etc/systemd/logind.conf

	HandlePowerKey=ignore    

then restart LoginD    

	systemctl restart systemd-logind.service
