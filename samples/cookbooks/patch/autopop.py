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
import os

from oslo.config import cfg 
from keystone.common import config
#from keystone.openstack.common import cfg
#from keystone.common import logging
from keystone.openstack.common import log
from keystone import exception
from keystone import identity
from keystone import assignment
from keystone.common import wsgi


# Environment variable used to pass the request context
CONTEXT_ENV = 'openstack.context'

# Environment variable used to pass the request params
PARAMS_ENV = 'openstack.params'

CONF = config.CONF

opts = [cfg.StrOpt('default_tenant_id', default=None),
        cfg.StrOpt('default_project_id', default=None),
        cfg.StrOpt('default_role_id', default=None),
        cfg.StrOpt('default_project', default=None),
        cfg.StrOpt('default_role', default=None)
       ]

CONF.register_opts(opts, group='auto_population')

#LOG = logging.getLogger(__name__)
LOG = log.getLogger(__name__)

DEFAULT_DOMAIN_ID = CONF.identity.default_domain_id

# API URL constants
V3_API = 'v3'
V2_API = 'v2'

# User ID column length in DB
USR_ID_COL_LEN = 64

class AutoPopulation(wsgi.Middleware):
    """Python paste middleware filter which
    authenticates requests which use simple tokens.

    To configure this middleware:
    (a) Define following properties in your conf file.

    [auto_population]
    default_project= 
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

    (d) This plugin follow the same rule with ldapauth to support domain specific
    configuration with
    
    (e) Make sure this file/class exists in your keystone
    installation under keystone.middleware

    """

    def __init__(self, app, **config):
        # initialization vector
        self._iv = '\0' * 16
        self.identity_api = identity.Manager()
        self.assignment_api = assignment.Manager()
        super(AutoPopulation, self).__init__(app)
        self.autopop_config = {}
        #domain_ref = self.identity_api.get_domain( self.identity_api, DEFAULT_DOMAIN_ID)
        domain_ref = self.identity_api.get_domain(DEFAULT_DOMAIN_ID)
        self.default_domain = domain_ref['name']
        self.common_autopop_config = CONF.auto_population
        self.log_ldap_config(CONF)
        
        self.domain_specific_drivers_enabled = CONF.ldap_pre_auth.domain_specific_drivers_enabled
        
        if self.domain_specific_drivers_enabled:
            domain_config_dir = CONF.ldap_pre_auth.domain_config_dir
            if not os.path.isdir(domain_config_dir):
                raise ValueError( 'Domain config directory %s is not a valid path' % domain_config_dir)	
            self._load_domain_config( domain_config_dir)

        LOG.debug('Initialization complete')
        
    def configure(self, conf):
        conf.register_opt(cfg.StrOpt('default_project', default=None), group='auto_population')
        conf.register_opt(cfg.StrOpt('default_role', default=None), group='auto_population')
        conf.register_opt(cfg.StrOpt('default_tenant_id', default=None), group='auto_population')
        conf.register_opt(cfg.StrOpt('default_project_id', default=None), group='auto_population')
        conf.register_opt(cfg.StrOpt('default_role_id', default=None), group='auto_population')

    def log_ldap_config(self, conf):
        LOG.debug('default_project: %s' % conf.auto_population.default_project)
        LOG.debug('default_role: %s' % conf.auto_population.default_role)
        LOG.debug('default_tenant_id: %s' % conf.auto_population.default_tenant_id)
        LOG.debug('default_project_id: %s' % conf.auto_population.default_project_id)
        LOG.debug('default_role_id: %s' % conf.auto_population.default_role_id)

    def _load_domain_config(self, domain_config_dir):
        LOG.debug('Loading domin config files from: %s' % domain_config_dir)
        for r, d, f in os.walk(domain_config_dir):
            for file in f:
                if file.startswith('keystone.') and file.endswith('.conf'):
                    names = file.split('.')
                    if len(names) == 3:
                        domain = names[1]
                        #domain_ref = self.identity_api.get_domain_by_name(domain)
                        LOG.debug('Found valid domain config file for: %s' % domain)
                        conf = cfg.ConfigOpts()
                        self.configure( conf=conf )
                        conf(args=[], project='keystone', default_config_files=[os.path.join(r, file)])
                        if conf.auto_population:
                            self.autopop_config[domain] = conf.auto_population
                            self.log_ldap_config(conf)
                    else:
                        LOG.debug('Ignoring file (%s) while scanning domain config directory' % file)
                    
    def _get_autopop_config_by_domain(self, domain):
        autopop_config = self.common_autopop_config
        if domain and self.autopop_config.get(domain, None):
            autopop_config =  self.autopop_config[domain]
        return autopop_config

    def get_role_by_name(self, role_name):
        role = None
        #roles = self.identity_api.list_roles( self.identity_api )
        roles = self.assignment_api.list_roles()
        for item in roles:
            if item['name'] == role_name:
                role = item
                break;
        return role

    def _is_user_id_valid(self, user_id):
        """Validation against user id goes here.
        """

        # user id must not exceed the column length in keystone db
        if len(user_id) >= USR_ID_COL_LEN:
            return False

        # sco cannot deal with a user id containing spaces for now
        if ' ' in user_id:
            return False

        return True

    def process_request(self, request):
        if (request.environ.get('PATH_INFO', None) != '/tokens' and
            request.environ.get('PATH_INFO', None) != '/auth/tokens'):
            # only populate user for tokens request
            return self.application
        username = request.environ.get('REMOTE_USER', None)
        if username is not None:
            # authenticated upstream
            script_name = request.environ.get('SCRIPT_NAME', None)
            if script_name is None:
                return self.application
            domain_id = None
            domain_name = None
            username_part = None
            try:
                if script_name.find(V3_API) >= 0:
                    #names = username.rsplit('@', 1)
                    #username_part = names.pop(0)
                    #if names and len(names) > 0 :
                    #    domain_name = names[0]
                    #    #domain_ref = self.identity_api.get_domain_by_name( self.identity_api, domain_name)
                    #    domain_ref = self.identity_api.get_domain_by_name(domain_name)
                    #    domain_id = domain_ref['id']
                    #else:
                    #    domain_id = DEFAULT_DOMAIN_ID
                    #    domain_name = self.default_domain
                    username_part = username
                    #domain_id = DEFAULT_DOMAIN_ID
                    #domain_id = request.environ.get('REMOTE_DOMAIN', None)
                    domain_name = request.environ.get('REMOTE_DOMAIN', None)
                    if domain_name is not None:
                        domain_ref = self.identity_api.get_domain_by_name(domain_name)
                        domain_id = domain_ref['id']
                    else:
                        domain_id = DEFAULT_DOMAIN_ID
                        domain_name = self.default_domain
                elif script_name.find(V2_API) >= 0:
                    username_part = username
                    domain_id = DEFAULT_DOMAIN_ID
                    domain_name = self.default_domain
            except exception.DomainNotFound, e:
                LOG.debug("Cound not find domain with name:" % domain_name)
                return self.application
            user_ref = None
            try:
                #user_ref = self.identity_api.get_user_by_name(self.identity_api, username_part, domain_id)
                user_ref = self.identity_api.get_user_by_name(username_part, domain_id)
            except exception.UserNotFound, e:
                LOG.debug("Could not find remote user in keystone, proceeding with auto-population")
            if user_ref is None:
                user_id = request.environ.get('REMOTE_USER_ID', None)
                user_pwd = request.environ.get('REMOTE_USER_PWD', None)
                if user_id is None:
                    LOG.info("Could not find provided user id to populate remote user %s" % username)
                    return wsgi.render_exception(exception.UnexpectedError("Could not find provided user id to populate remote user"))
                if not self._is_user_id_valid(user_id):
                    return wsgi.render_exception(exception.UnexpectedError("Illegal user ID: %s" % user_id))
                user_mail = request.environ.get('REMOTE_USER_EMAIL', '')
                user_dict = {
                    'id' : user_id,
                    'name' : username_part,
                    'domain_id' : domain_id,
                    'email': user_mail,
                    'password': uuid.uuid4().hex,
                    'enabled' : True,
                    'description': 'Automatically created user by virtue of successful LDAP Authentication',
                }
                try:
                    LOG.debug("Create user %s" % user_dict)
                    #self.identity_api.create_user(self.identity_api, user_dict['id'], user_dict)
                    self.identity_api.create_user(user_dict['id'], user_dict)
                except Exception, e:
                    #LOG.info("Create user failed due to: " + str(e))
                    LOG.info("Create user failed due to: %s" % e.message)
                    return wsgi.render_exception(e)
                
                LOG.debug("Created user %s in keystone automatically." % username_part )
                try:
                    autopop_config = self._get_autopop_config_by_domain(domain_name)

                    # Allow for support of v2 style specification of default tenant_id
                    if autopop_config.default_project_id is None and autopop_config.default_tenant_id is not None:
                        autopop_config.default_project_id = autopop_config.default_tenant_id

                    # Check for default project specified by name
                    if autopop_config.default_project_id is None and autopop_config.default_project is not None:
                        #project = self.identity_api.get_project_by_name( self.identity_api, autopop_config.default_project, domain_id)
                        project = self.assignment_api.get_project_by_name(autopop_config.default_project, domain_id)
                        autopop_config.default_project_id = project['id']

                    # Check for additional role specified by name                  
                    if autopop_config.default_role_id is None and autopop_config.default_role is not None:
                        role = self.get_role_by_name(autopop_config.default_role)
                        autopop_config.default_role_id = role['id']
                  
                    context = request.environ.get(CONTEXT_ENV, {})

                    # If we have a default project defined, then let's add the roles to it
                    if autopop_config.default_project_id is not None:
                       #self.identity_api.add_user_to_project(autopop_config.default_project_id, user_dict['id'])
                       self.assignment_api.add_user_to_project(autopop_config.default_project_id, user_dict['id'])
                       #user_dict['tenantId'] = autopop_config.default_project_id
                       user_dict['default_project_id'] = autopop_config.default_project_id
                       #self.identity_api.update_user(context, user_dict['id'], user_dict)   
                       self.identity_api.update_user(user_dict['id'], user_dict)   
                       if autopop_config.default_role_id is not None:
                           #self.identity_api.add_role_to_user_and_project(user_dict['id'], autopop_config.default_project_id, autopop_config.default_role_id)
                           self.assignment_api.add_role_to_user_and_project(user_dict['id'], autopop_config.default_project_id, autopop_config.default_role_id)
                 
                except Exception, e:
                    # We created the user, but failed adding a role. Let's not fail the creation, but log a warning,
                    #LOG.warning("Add role to user failed during auto population due to: " + str(e))
                    LOG.warning("Add role to user failed during auto population due to: %s" % e.message)
