# vim: tabstop=4 shiftwidth=4 softtabstop=4

# =================================================================
# Licensed Materials - Property of IBM
#
# (c) Copyright IBM Corp. 2013 All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
# =================================================================

import os
import base64
import json
import time
import webob
import ldap
from ldap import filter as ldap_filter


from oslo.config import cfg
#from keystone import config
from keystone.common import config
#from keystone.openstack.common import cfg
#from keystone.common import logging
from keystone.openstack.common import log
from keystone import exception
from keystone import identity
from keystone.common import wsgi
#from keystone.common.ldap import fakeldap

# Environment variable used to pass the request context
CONTEXT_ENV = 'openstack.context'

# Environment variable used to pass the request params
PARAMS_ENV = 'openstack.params'

LDAP_TLS_CERTS = {'never': ldap.OPT_X_TLS_NEVER,
                  'demand': ldap.OPT_X_TLS_DEMAND,
                  'allow': ldap.OPT_X_TLS_ALLOW}

CONF = config.CONF

NAME_ATTR_DEFAULT = 'cn'

opts = [cfg.StrOpt('url', default='ldap://localhost'),
        cfg.StrOpt('user', default=None),
        cfg.StrOpt('password', default=None),
        cfg.StrOpt('user_tree_dn', default='cn=users,dc=example,dc=com'),
        cfg.StrOpt('user_attribute_name', default='cn'),
        cfg.StrOpt('user_name_attribute', default=NAME_ATTR_DEFAULT),
        cfg.StrOpt('user_mail_attribute'),
        cfg.StrOpt('user_id_attribute', default='dn'),
        cfg.StrOpt('user_objectclass', default='*'),
        cfg.StrOpt('user_filter'),
        cfg.BoolOpt('pass_through', default=True),
        cfg.StrOpt('tls_cacertfile', default=None),
        cfg.StrOpt('tls_cacertdir', default=None),
        cfg.StrOpt('tls_req_cert', default=None),
        cfg.BoolOpt('use_tls', default=False),
        cfg.BoolOpt('domain_specific_drivers_enabled', default=False),
        cfg.StrOpt('domain_config_dir', default='/etc/keystone/domains'),
        cfg.ListOpt('non_ldap_users', default=[])]

CONF.register_opts(opts, group='ldap_pre_auth')

#LOG = logging.getLogger(__name__)
LOG = log.getLogger(__name__)
DEFAULT_DOMAIN_ID = CONF.identity.default_domain_id

# API URL constants
V3_API = 'v3'
V2_API = 'v2'


class LdapAuthAuthentication(wsgi.Middleware):
    """Python paste middleware filter which
    authenticates requests with ldap server.

    To configure this middleware:
    (a) Define following properties in your
    conf file, you can skip the user and password
    if your ldap server supports anonymous query.
    
    [ldap_pre_auth]
    url = ldap://localhost
    user_tree_dn = cn=users,dc=example,dc=com
    user_name_attribute = mail
    user = cn=admin,cn=users,dc=example,dc=com
    password = balabala
    pass_through = True
    
    (b) If you don't want to let keystone continue to authenticate
    the user when ldap server authenticate failed, you can
    set pass_through to False under ldap_pre_auth group
    (it's set to True by default).

    (c) If you want to connect ldap with ssl or tls, 
    define following properties in your conf. 
    Please note, using ssl (by setting the url to ldaps://)
    and tls (by setting use_tls = True) cannot be 
    combined together.
    
    [ldap_pre_auth]
    url = ldap(s)://localhost
    tls_cacertfile = /path/to/certfile
    tls_cacertdir = /path/to/certdir
    tls_req_cert = demand
    use_tls = True | False

    (d) In your conf or paste ini, define a filter for
    this class. For example:

    [filter:ldapauth]
    paste.filter_factory = keystone.middleware.ldapauth:
    LdapAuthAuthentication.factory

    (e) Add the filter to the pipeline you wish to execute it.
    The filter should come after the 'json_body' and 'xml_body'
    filter but before the actual app in the pipeline, like:
    
    [pipeline:public_api]
    pipeline = xml_body json_body simpletoken ldapauth debug
    [pipeline:admin_api]
    pipeline = xml_body json_body simpletoken ldapauth debug
    
    (f) If you want domain specific configuration for ldap, define
    following properties in your conf:
    
    [ldap_pre_auth]
    domain_specific_drivers_enabled = True
    domain_config_dir = /etc/keystone/domain/
    
    This plugin will load configuration files in the directory
    specified by domain_config_dir, the configuration file's name should
    look like this:
    keystone.<domain_name>.conf
    
    (f) Make sure this file/class exists in your keystone
    installation under keystone.middleware

    Authentication is request based on ldap user and password.
    """

    def __init__(self, app, **config):
        
        super(LdapAuthAuthentication, self).__init__(app)
        # initialization vector
        self._iv = '\0' * 16
        self.identity_api = identity.Manager()
        self.ldap_config = {}
        #domain_ref = self.identity_api.get_domain( self.identity_api, DEFAULT_DOMAIN_ID)
        domain_ref = self.identity_api.get_domain(DEFAULT_DOMAIN_ID)
        self.default_domain = domain_ref['name']
        self.common_ldap_config = CONF.ldap_pre_auth
        self.log_ldap_config(CONF)
        if self.common_ldap_config.tls_cacertfile is not None:
            if not os.path.isfile(self.common_ldap_config.tls_cacertfile):
                raise IOError("tls_cacertfile %s not found or is not a file" % self.common_ldap_config.tls_cacertfile )
            ldap.set_option(ldap.OPT_X_TLS_CACERTFILE, self.common_ldap_config.tls_cacertfile)
        if self.common_ldap_config.tls_cacertdir is not None:
            if not os.path.isdir(self.common_ldap_config.tls_cacertdir):
                raise IOError( "tls_cacertdir %s not found or is not a directory" % self.common_ldap_config.tls_cacertdir)
            ldap.set_option(ldap.OPT_X_TLS_CACERTDIR, self.common_ldap_config.tls_cacertdir)
        if self.common_ldap_config.tls_req_cert is not None:
            if self.common_ldap_config.tls_req_cert in LDAP_TLS_CERTS:
                ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, LDAP_TLS_CERTS[self.common_ldap_config.tls_req_cert])
            else:
                raise ValueError( 'Invalid LDAP TLS certs option: %s\nChoose one of: %s' % (self.common_ldap_config.tls_req_cert, LDAP_TLS_CERTS.keys()) )

        self._validate_ldap_config( self.common_ldap_config)
        self.domain_specific_drivers_enabled = CONF.ldap_pre_auth.domain_specific_drivers_enabled
        
        if self.domain_specific_drivers_enabled:
            domain_config_dir = self.common_ldap_config.domain_config_dir
            if not os.path.isdir(domain_config_dir):
                raise ValueError( 'Domain config directory %s is not a valid path' % domain_config_dir)	
            self._load_domain_config( domain_config_dir)

        self.non_ldap_users = CONF.ldap_pre_auth.non_ldap_users

        LOG.debug('Initialization complete')
            
    def _validate_ldap_config(self, ldap_config):
        if ldap_config and ldap_config.url:
            using_ldaps = ldap_config.url and ldap_config.url.lower().startswith("ldaps")
            if ldap_config.use_tls and using_ldaps:
                raise AssertionError(_('Invalid TLS / LDAPS combination'))
        
        if ldap_config.user_attribute_name != NAME_ATTR_DEFAULT and ldap_config.user_name_attribute == NAME_ATTR_DEFAULT:
            ldap_config.user_name_attribute = ldap_config.user_attribute_name
            LOG.debug('Depreciated config variable (user_attribute_name) being used: %s' % ldap_config.user_name_attribute)

    def configure(self, conf):
        conf.register_opt(cfg.StrOpt('url'), group='ldap_pre_auth')
        conf.register_opt(cfg.StrOpt('user'), group='ldap_pre_auth')
        conf.register_opt(cfg.StrOpt('password'), group='ldap_pre_auth')
        conf.register_opt(cfg.StrOpt('user_tree_dn', default='cn=users,dc=example,dc=com'), group='ldap_pre_auth')
        conf.register_opt(cfg.StrOpt('user_attribute_name', default=NAME_ATTR_DEFAULT), group='ldap_pre_auth')
        conf.register_opt(cfg.StrOpt('user_name_attribute', default=NAME_ATTR_DEFAULT), group='ldap_pre_auth')
        conf.register_opt(cfg.StrOpt('user_mail_attribute'), group='ldap_pre_auth')
        conf.register_opt(cfg.StrOpt('user_id_attribute', default='dn'), group='ldap_pre_auth')
        conf.register_opt(cfg.StrOpt('user_objectclass', default='*'), group='ldap_pre_auth')
        conf.register_opt(cfg.StrOpt('user_filter'), group='ldap_pre_auth')
        conf.register_opt(cfg.BoolOpt('pass_through', default=True), group='ldap_pre_auth')
        # python-ldap 2.3 doesn't support tls connection specific settings, it only support module level setting
        # TODO (henry.nash@uk.ibm.com): 2.4 supports this by connection, so we need to update to that first
        # However, we load them here anway, in anticipation of that support.
        conf.register_opt(cfg.StrOpt('tls_cacertfile'), group='ldap_pre_auth')
        conf.register_opt(cfg.StrOpt('tls_cacertdir'), group='ldap_pre_auth')
        conf.register_opt(cfg.StrOpt('tls_req_cert'), group='ldap_pre_auth')
        conf.register_opt(cfg.BoolOpt('use_tls', default=False), group='ldap_pre_auth')
        conf.register_opt(cfg.ListOpt('non_ldap_users', default=[]), group='ldap_pre_auth')

    def log_ldap_config(self, conf):
        LOG.debug('url: %s' % conf.ldap_pre_auth.url)
        LOG.debug('user_tree_dn: %s' % conf.ldap_pre_auth.user_tree_dn)
        LOG.debug('user_attribute_name: %s' % conf.ldap_pre_auth.user_attribute_name)
        LOG.debug('user_name_attribute: %s' % conf.ldap_pre_auth.user_name_attribute)
        LOG.debug('user_mail_attribute: %s' % conf.ldap_pre_auth.user_mail_attribute)
        LOG.debug('user_id_attribute: %s' % conf.ldap_pre_auth.user_id_attribute)
        LOG.debug('user_objectclass: %s' % conf.ldap_pre_auth.user_objectclass)
        LOG.debug('user_filter: %s' % conf.ldap_pre_auth.user_filter)
        LOG.debug('pass_through: %s' % conf.ldap_pre_auth.pass_through)
        LOG.debug('use_tls: %s' % conf.ldap_pre_auth.use_tls)
        LOG.debug('tls_cacertfile: %s' % conf.ldap_pre_auth.tls_cacertfile)
        LOG.debug('tls_cacertdir: %s' % conf.ldap_pre_auth.tls_cacertdir)
        LOG.debug('tls_req_cert: %s' % conf.ldap_pre_auth.tls_req_cert)
        LOG.debug('non_ldap_users: %s' % conf.ldap_pre_auth.non_ldap_users)

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
                        if conf.ldap_pre_auth:
                            self._validate_ldap_config(conf.ldap_pre_auth)
                            self.ldap_config[domain] = conf.ldap_pre_auth
                            self.log_ldap_config(conf)
                    else:
                        LOG.debug('Ignoring file (%s) while scanning domain config directory' % file)
                        
    def get_connection(self, ldap_config):
        LOG.debug("Requesting connection to: " + ldap_config.url)
        #if ldap_config.url.startswith('fake://'):
        #    conn = fakeldap.FakeLdap(ldap_config.url)
        #else:
        #LOG.debug("========================================= " + str(self.ldap_url))
        conn = ldap.initialize(ldap_config.url)
        if ldap_config.use_tls:
            conn.start_tls_s()
        return conn
        
    def user_to_dn(self, username, ldap_config):
        user_dn = None
        user_id = None
        user_mail = None
        try:
            conn = self.get_connection(ldap_config)
            LOG.debug("Connection obtained to try and map user %s to dn" % username)
            if ldap_config.user is not None:
                LOG.debug("Binding being requested for user: %s" % ldap_config.user)
                conn.simple_bind_s(ldap_config.user, ldap_config.password)
                LOG.debug("Binding obtained")

            query = ('(&(%(name_attr)s=%(name)s)'
                     '%(filter)s'
					 '(objectClass=%(object_class)s))'
                     % {'name_attr': ldap_config.user_name_attribute,
                        'name': ldap_filter.escape_filter_chars(username),
						'filter': (ldap_config.user_filter or ''),
                        'object_class': ldap_config.user_objectclass})
            # Build the attribute list...we always want the dn...
            attrlist = ['dn']
            # ...plus additionally a specific attribute for the user_id and email
            if ldap_config.user_id_attribute != 'dn':
                attrlist.append(ldap_config.user_id_attribute)
            if ldap_config.user_mail_attribute is not None:
                attrlist.append(ldap_config.user_mail_attribute)

            users = conn.search_s(ldap_config.user_tree_dn, ldap.SCOPE_SUBTREE, query, attrlist)
                        
            for dn, attrs in users:
                user_dn = dn
                if ldap_config.user_id_attribute == 'dn':
                    user_id = dn
                else:
                    value = attrs[ldap_config.user_id_attribute]
                    if (isinstance(value, list)):
                        user_id = value[0]
                    else:
                        user_id = value
                value = attrs.get(ldap_config.user_mail_attribute, None)
                if (isinstance(value, list)):
                    user_mail = value[0]
                else:
                    user_mail = value
                break
        except Exception, e:
            LOG.debug("Ldap user to dn failed due to: " + str(e))
        return user_dn, user_id, user_mail
        
    def process_v2_request(self, request):
        params = request.environ.get(PARAMS_ENV, None)
        auth = None
        
        # only try ldap auth when passwordCredentials is set
        if params is not None:
            auth = params.get('auth', None)

        if auth and auth.get('passwordCredentials', None) is not None:
            username = auth['passwordCredentials'].get('username', None)
            if username in self.non_ldap_users:
                return self.application

            try:
                user_ref = None
                if username is None:
                    user_id = auth['passwordCredentials'].get('userId', None)
                    if user_id is not None:
                        try:
                            # the user_id look-up is only supported when then the 
                            # user already exists in keystone, no auto-population here.
                            user_ref = self.identity_api.get_user(self.identity_api, user_id)
                            username = user_ref['name']
                        except exception.UserNotFound:
                            raise AssertionError('Invalid user id')
                password = auth['passwordCredentials'].get('password', None)
                if username is not None:
                    user_id, user_mail = self.authenticate(request, username, password)
                    if user_id is not None:
                        context = request.environ.get(CONTEXT_ENV, {})
                        # indicate remote authentication via context
                        context['REMOTE_USER'] = username
                        request.environ[CONTEXT_ENV] = context
                        request.environ['REMOTE_USER'] = username
                        request.environ['REMOTE_USER_ID'] = user_id
                        request.environ['REMOTE_USER_PWD'] = password
                        if user_mail is None:
                            user_mail = ''
                        request.environ['REMOTE_USER_EMAIL'] = user_mail
            except Exception, e:
                LOG.debug("Ldap authentication failed due to: " + str(e))
                raise exception.Unauthorized("Authentication failed")
                
    def process_v3_request(self, request):
        params = request.environ.get(PARAMS_ENV, None)
        auth = None

        # only try simple token authn when identity is set for v3 api
        if params is not None:
            auth = params.get('auth', None)

        if auth and auth.get('identity', None) is not None:
            user_name = None
            domain_name = self.default_domain
            identity_pwd = auth['identity'].get('password', None)
            if identity_pwd and identity_pwd.get('user', None) is not None:
                try:
                    username = self._get_user_from_v3_request(
                                                         identity_pwd['user'])
                    if username in self.non_ldap_users:
                        return self.application

                    if identity_pwd['user'] and identity_pwd['user'].get('domain',
                                                              None) is not None:
                        domain_name = self._get_domain_from_v3_request(
                                     identity_pwd['user'].get('domain', None))
                    if username is not None:
                        password = identity_pwd['user'].get('password', None)
                        user_id, user_mail = self.authenticate(request, username, password, domain_name)
                        if user_id is not None:
                            LOG.debug('Authenticated for: ' + username + ', domain: ' + domain_name)
                            identity_methods = auth['identity'].get('methods', None)
                            context = request.environ.get(CONTEXT_ENV, {})
                            # indicate remote authentication via context
                            #remote_user = username + "@" + domain_name
                            remote_user = username
                            context['REMOTE_USER'] = remote_user 
                            request.environ[CONTEXT_ENV] = context
                            request.environ['REMOTE_USER'] = remote_user
                            request.environ['REMOTE_USER_ID'] = user_id
                            #request.environ['REMOTE_USER_PWD'] = password
                            if user_mail is None:
                                user_mail = ''
                            request.environ['REMOTE_USER_EMAIL'] = user_mail
                            request.environ['REMOTE_DOMAIN'] = domain_name 
                            if identity_methods is not None and len(identity_methods):
                                del identity_methods[:]
                except Exception, e:
                    LOG.debug("Ldap authentication failed due to: " + str(e))
                    raise exception.Unauthorized("Authentication failed")
    
    
    def process_request(self, request):
        if request.environ.get('REMOTE_USER', None) is not None:
            # authenticated upstream
            return self.application
        if ( request.environ.get('PATH_INFO', None) != '/tokens' and 
             request.environ.get('PATH_INFO', None) != '/auth/tokens'):
            # only authenticate for tokens request
            return self.application
        script_name = request.environ.get('SCRIPT_NAME', None)
        if script_name is None:
            return self.application

        if script_name.find(V3_API) >= 0:
            self.process_v3_request(request)
        elif script_name.find(V2_API) >= 0:
            self.process_v2_request(request)
        else:
            return self.application
        
    def _get_user_from_v3_request(self, user):
        username = user.get('name', None)
        user_id = user.get('id', None)
        if not username and user_id:
            user_ref = self.identity_api.get_user(self.identity_api, user_id)
            username = user_ref['name']
        return username

    def _get_domain_from_v3_request(self, domain):
        domain_id = domain.get('id', None)
        domain_name = domain.get('name', None)
        if not domain_name and domain_id:
            domain_ref = self.identity_api.get_domain( self.identity_api, domain_id)
            domain_name = domain_ref['name']
        return domain_name
    
    def _get_ldap_config_by_domain(self, domain):
        ldap_config = self.common_ldap_config
        if domain and self.ldap_config.get(domain, None):
            ldap_config =  self.ldap_config[domain]
        return ldap_config

    def authenticate(self, request, username, password=None, domain=None):
        """Authenticate the request if applicable using ldap"""
        if not domain:
            domain = self.default_domain
        ldap_config = self._get_ldap_config_by_domain(domain)
        if ldap_config.url is None:
            LOG.debug('Authenticating for user %s, no LDAP url defined for domain %s, passing through to keystone' % (username, domain))
        else:
            user_dn, user_id, user_mail = self.user_to_dn(username, ldap_config)
            LOG.debug('Mapped user %s to dn %s and ID %s ' % (username, user_dn, user_id))
            if user_dn is None:
                if not ldap_config.pass_through:
                    raise exception.Unauthorized('Invalid user / password')
                else:
                    LOG.debug('User not found in LDAP, passing through to keystone')
            else:
                conn = self.get_connection(ldap_config)
                LOG.debug('Connection Obtained')
                if password is None or password == '':
                    raise exception.Unauthorized('No password')
                conn.simple_bind_s(user_dn, password)
                LOG.debug('Binding Obtained')
            return user_id, user_mail
