# vim: tabstop=4 shiftwidth=4 softtabstop=4

# =================================================================
# Licensed Materials - Property of IBM
#
# (c) Copyright IBM Corp. 2013 All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
# =================================================================
import base64
import json
import time
import webob
import uuid


from keystone import config
#from keystone.openstack.common import cfg
#from keystone.common import logging
from keystone.openstack.common import log
from keystone import exception
from keystone import identity
from keystone import assignment
from keystone.common import wsgi
from oslo.config import cfg


# Environment variable used to pass the request context
CONTEXT_ENV = 'openstack.context'

# Environment variable used to pass the request params
PARAMS_ENV = 'openstack.params'

CONF = config.CONF

opts = [cfg.StrOpt('default_project', default=None),
        cfg.StrOpt('default_role', default=None)
       ]

CONF.register_opts(opts, group='auto_population')

#config.register_str('default_tenant_id', group='auto_population')
#config.register_str('default_role_id', group='auto_population')

#LOG = logging.getLogger(__name__)
LOG = log.getLogger(__name__)


class AutoPopulation(wsgi.Middleware):
    """Python paste middleware filter which
    authenticates requests which use simple tokens.

    To configure this middleware:
    (a) Define following properties in your conf file.

    [auto_population]
    default_tenant = 
    default_role = 


    (b) In your conf or paste ini, define a filter for this class. For example:

    [filter:autopop]
    paste.filter_factory = keystone.middleware.autopop:AutoPopulation.factory

    (c) Add the filter to the pipeline you wish to execute it.
    The filter should come after all the authentication
    filter but before the actual app in the pipeline, like:
    
    [pipeline:public_api]
    pipeline = xml_body json_body simpletoken ldapauth autopop debug
    [pipeline:admin_api]
    pipeline = xml_body json_body simpletoken ldapauth autopop debug 

    (d) Make sure this file/class exists in your keystone
    installation under keystone.middleware

    """

    def __init__(self, app, **config):
        # initialization vector
        self._iv = '\0' * 16
        self.default_tenant = CONF.auto_population.default_project
        self.default_role = CONF.auto_population.default_role
        self.identity_api = identity.Manager()
        self.assignment_api = assignment.Manager()
        self.default_domain_id = CONF.identity.default_domain_id
        super(AutoPopulation, self).__init__(app)

    def process_request(self, request):

        if request.environ.get('PATH_INFO', None) != '/tokens':
            # only populate user for tokens request
            return self.application
        username = request.environ.get('REMOTE_USER', None)
        if username is not None:
            # authenticated upstream
            user_ref = None
            try:
		#LOG.debug("******************** username: " + str(username) + "**************")
		#LOG.debug("******************** default_domain_id: " + str(self.default_domain_id) + "********************")
                user_ref = self.identity_api.get_user_by_name(username, self.default_domain_id)
            except exception.UserNotFound, e:
                LOG.debug("Could not find remote user in keystone, proceeding with auto-population")
            if user_ref is None:
                user_id = request.environ.get('REMOTE_USER_ID', None)
                if user_id is None:
                    user_id = uuid.uuid4().hex
                user_dict = {
                    'id' : uuid.uuid4().hex,
                    'name' : username,
                    'email': '',
                    'password': uuid.uuid4().hex,
                    'enabled' : True,
                    'domain_id': self.default_domain_id,
                    'description': 'Automatically created user by virtue of successful LDAP Authentication',
                }
                try:
                    LOG.debug("Create user %s" % user_dict)
                    self.identity_api.create_user(user_dict['id'], user_dict)
                except Exception, e:
                    LOG.info("Create user failed due to: " + str(e))
                    return wsgi.render_exception(e)
                    LOG.debug("Created user %s in keystone automatically." % username )
                if self.default_tenant is not None and self.default_role is not None:
                    try:
                        tenants = self.identity_api.list_projects()
                        tenant_id = ""
                        for t in tenants:
                            if t['name'] == self.default_tenant:
                                tenant_id = t['id']
                                break
                        LOG.debug("default_tenant_id is %s"%tenant_id)
                        if not tenant_id:
                            return wsgi.render_exception(Exception("default_tenent does not exist", self.default_tenant))
                    	#context = request.environ.get(CONTEXT_ENV, {})
                    	self.assignment_api.add_user_to_project(tenant_id, user_dict['id'])
                    	user_dict['tenantId'] = self.default_tenant
                    	self.identity_api.update_user(user_dict['id'], user_dict)
                    except Exception, e:
                        LOG.info("Add role to user failed due to: %s" %e.args)
			            #LOG.info("Add role to user failed due to")
                        #return wsgi.render_exception(e)
