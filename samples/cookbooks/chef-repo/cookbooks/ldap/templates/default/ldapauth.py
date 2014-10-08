# vim: tabstop=4 shiftwidth=4 softtabstop=4

# =================================================================
# Licensed Materials - Property of IBM
#
# (c) Copyright IBM Corp. 2014 All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
# =================================================================

import os
import base64
import json
import time

import ldap
import ldap.filter
import webob

from keystone.common import wsgi
from keystone import config
from keystone import exception
from keystone import identity
from keystone.openstack.common import log
from oslo.config import cfg


# Environment variable used to pass the request context
CONTEXT_ENV = 'openstack.context'

# Environment variable used to pass the request params
PARAMS_ENV = 'openstack.params'

LDAP_TLS_CERTS = {'never': ldap.OPT_X_TLS_NEVER,
                  'demand': ldap.OPT_X_TLS_DEMAND,
                  'allow': ldap.OPT_X_TLS_ALLOW}

opts = [cfg.StrOpt('url', default='ldap://localhost'),
		cfg.StrOpt('user', default=None),
		cfg.StrOpt('password', default=None),
		cfg.StrOpt('user_tree_dn', default='cn=users,dc=example,dc=com'),
		cfg.StrOpt('user_attribute_name', default='cn'),
		cfg.StrOpt('pass_through', default=True),
		cfg.StrOpt('tls_cacertfile', default=None),
		cfg.StrOpt('tls_cacertdir', default=None),
		cfg.StrOpt('tls_req_cert', default=None),
		cfg.StrOpt('use_tls', default=False),
		cfg.StrOpt('user_id_attribute', default='dn'),
		cfg.ListOpt('non_ldap_users', default=[])]

CONF = config.CONF
CONF.register_opts(opts, group='ldap_pre_auth')
LOG = log.getLogger(__name__)


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
    user_attribute_name = mail
    user = cn=admin,cn=users,dc=example,dc=com
    password = balabala

    (b) If you want to connect ldap with ssl or tls, 
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

    (c) In your conf or paste ini, define a filter for
    this class. For example:

    [filter:ldapauth]
    paste.filter_factory = keystone.middleware.ldapauth:
    LdapAuthAuthentication.factory

    (d) Add the filter to the pipeline you wish to execute it.
    The filter should come after the 'json_body' and 'xml_body'
    filter but before the actual app in the pipeline, like:
    
    [pipeline:public_api]
    pipeline = xml_body json_body simpletoken ldapauth debug
    [pipeline:admin_api]
    pipeline = xml_body json_body simpletoken ldapauth debug
    
    (e) Make sure this file/class exists in your keystone
    installation under keystone.middleware

    Authentication is request based on ldap user and password.
    """

    def __init__(self, app, **config):
        
        super(LdapAuthAuthentication, self).__init__(app)
        # initialization vector
        self._iv = '\0' * 16
        self.ldap_url = CONF.ldap_pre_auth.url
        self.user_tree_dn = CONF.ldap_pre_auth.user_tree_dn
        self.user_attribute_name = CONF.ldap_pre_auth.user_attribute_name
        self.user = CONF.ldap_pre_auth.user
        self.password = CONF.ldap_pre_auth.password
        self.pass_through = CONF.ldap_pre_auth.pass_through
        self.identity_api = identity.Manager()
        self.tls_cacertfile = CONF.ldap_pre_auth.tls_cacertfile
        self.tls_cacertdir = CONF.ldap_pre_auth.tls_cacertdir
        self.tls_req_cert = CONF.ldap_pre_auth.tls_req_cert      
        self.use_tls = CONF.ldap_pre_auth.use_tls
        self.user_id_attribute = CONF.ldap_pre_auth.user_id_attribute
        self.non_ldap_users = CONF.ldap_pre_auth.non_ldap_users
        using_ldaps = self.ldap_url.lower().startswith("ldaps")
        if self.use_tls and using_ldaps:
            raise AssertionError(_('Invalid TLS / LDAPS combination'))
        if self.tls_cacertfile is not None:
            if not os.path.isfile(self.tls_cacertfile):
                raise IOError("tls_cacertfile %s not found or is not a file" % self.tls_cacertfile )
            ldap.set_option(ldap.OPT_X_TLS_CACERTFILE, self.tls_cacertfile)
        if self.tls_cacertdir is not None:
            if not os.path.isdir(self.tls_cacertdir):
                raise IOError( "tls_cacertdir %s not found or is not a directory" % self.tls_cacertdir)
            ldap.set_option(ldap.OPT_X_TLS_CACERTDIR, self.tls_cacertdir)
        if self.tls_req_cert is not None:
            if self.tls_req_cert in LDAP_TLS_CERTS:
                ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, LDAP_TLS_CERTS[self.tls_req_cert])
            else:
                raise ValueError( 'Invalid LDAP TLS certs option: %s\nChoose one of: %s' % (self.tls_req_cert, LDAP_TLS_CERTS.keys()) )

    def get_connection(self):
        #if self.ldap_url.startswith('fake://'):
        #conn = fakeldap.FakeLdap(self.ldap_url)
	LOG.debug("========================================= ")
        #else:
	LOG.debug("========================================= " + str(self.ldap_url))
        conn = ldap.initialize(self.ldap_url)
	LOG.debug("========================================= " + str(self.use_tls))
        if self.use_tls:
            conn.start_tls_s()
        return conn
        
    def user_to_dn(self, username=None):
        user_dn = None
        user_id = None
        try:
            if username is not None:
		LOG.debug("========================================= about to get connection")
                conn = self.get_connection()
		LOG.debug("========================================= get connection completed")
                if self.user is not None:
                    conn.simple_bind_s( self.user, self.password)
                query = '(%s=%s)' % ( self.user_attribute_name, ldap.filter.escape_filter_chars(username))
                if self.user_id_attribute == 'dn':
                    attrlist = ['dn']
                else:
                    attrlist = ['dn', self.user_id_attribute]
		LOG.debug("========================================= user_tree_dn: " + str(self.user_tree_dn) + "==========")
		LOG.debug("========================================= query: " + str(query) + "==============")
		LOG.debug("========================================= attrlist, SCOPE_SUBTREE: " + str(attrlist) + "================" + str(ldap.SCOPE_SUBTREE) + "=======")
                users = conn.search_s(self.user_tree_dn, ldap.SCOPE_SUBTREE, query, attrlist)
		LOG.debug("========================================= queried users: " + str(users) + "==================")
                            
                for dn, attrs in users:
		    LOG.debug("======================================= user_dn: " + str(dn) + "================")
                    user_dn = dn
                    if self.user_id_attribute == 'dn':
                        user_id = dn
                    else:
                        value = attrs[self.user_id_attribute]
                        if (isinstance(value, list)):
                            user_id = value[0]
                        else:
                            user_id = value
                    break
        except Exception, e:
            LOG.debug("Ldap user to dn failed due to: " + str(e))
        return user_dn, user_id

    def process_request(self, request):
        LOG.debug("Starting ldapauth... ")
        if request.environ.get('REMOTE_USER', None) is not None:
            # authenticated upstream
            LOG.debug("========================================= authenticated upstream")
            return self.application
        if request.environ.get('PATH_INFO', None) != '/tokens':
            # only authenticate for tokens request
            LOG.debug("========================================= only authenticate for tokens request")
            return self.application
            
        params = request.environ.get(PARAMS_ENV, None)
        auth = None

        # only try ldap auth when passwordCredentials is set
        if params is not None:
            auth = params.get('auth', None)

        LOG.debug("========================================= %s" % auth)
        if auth and auth.get('passwordCredentials', None) is not None:
            LOG.debug("========================================= has auth")
            username = auth['passwordCredentials'].get('username', None)
            if username in self.non_ldap_users:
                LOG.debug("========================================= skip non-ldap user %s" % username)
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
                    user_dn, user_id = self.user_to_dn(username)
                    if user_dn is None:
                        if not self.pass_through:
                            raise exception.Unauthorized('Invalid user / password')
                    else:
                        if self.authenticate(request, user_dn, password):
                            context = request.environ.get(CONTEXT_ENV, {})
                            # indicate remote authentication via context
                            context['REMOTE_USER'] = username
                            request.environ[CONTEXT_ENV] = context
                            request.environ['REMOTE_USER'] = username
                            request.environ['REMOTE_USER_ID'] = user_id
            except Exception, e:
                LOG.debug("Ldap authentication failed due to: " + str(e))
                raise exception.Unauthorized("Authentication failed")

    def authenticate(self, request=None, username=None, password=None):
        """Authenticate the request if applicable using ldap"""
        conn = self.get_connection()
        conn.simple_bind_s(username, password)
        return True
