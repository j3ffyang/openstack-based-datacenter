dnsconfig Cookbook
==================
This cookbook provide the function of provisioning forward db file for dns service.


Requirements
------------
dnsconfig cookbook needs named service installed previously.


Attributes
----------
no attributes need to be set currently.

Usage
-----
#### dnsconfig::default
You can change the template file directly when the dns configuration need to be changed. the dns configuration will be changed automaticlly after the cookbook been executed.

Just include `dnsconfig` in your role's `run_list`:

```
{
  "name":"my_node",
  "run_list": [
    "recipe[dnsconfig]"
  ]
}
```

License and Authors
-------------------
Authors: feicfei@cn.ibm.com 

