# -*- coding: utf-8 -*-

# Copyright 2016 99Cloud Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

import os

from django.utils.translation import ugettext_lazy as _  # noqa


# Dictionary of currently available angular features
ANGULAR_FEATURES = {
    'images_panel': True,
    'flavors_panel': True,
    'users_panel': True,
}

# Settings overrides
SITE_BRANDING = 'Animbus Cloud Management Platform'

AVAILABLE_THEMES = [
    ('default', 'Default', 'themes/default'),
    ('material', 'Material', 'themes/material'),
    ('contrib', 'Contrib', 'themes/contrib'),
]

DEFAULT_THEME = 'contrib'

LANGUAGES = (
    ('en', 'English'),
    ('zh-cn', 'Simplified Chinese'),
)
LANGUAGE_CODE = 'zh-cn'

TIME_ZONE = "Asia/Shanghai"

SESSION_TIMEOUT = 86400

OPENSTACK_IMAGE_BACKEND = {
    'image_formats': [
        ('', _('Select Image Format')),
        ('raw', _('Raw')),
        ('qcow2', _('QCOW2 - QEMU Emulator')),
        ('iso', _('ISO - Optical Disk Image')),
        ('aki', _('AKI - Amazon Kernel Image')),
        ('ari', _('ARI - Amazon Ramdisk Image'))
    ]
}

# Enable keystone v3
OPENSTACK_API_VERSIONS = {
    "identity": 3,
}

OPENSTACK_KEYSTONE_URL = "http://%s:5000/v3" % 172.16.214.112

OPENSTACK_ENDPOINT_TYPE = "internalURL"

# Enable password setting in launch instance form
OPENSTACK_HYPERVISOR_FEATURES['can_set_password'] = True

# Contrib middleware
MIDDLEWARE_CLASSES += (
    'openstack_dashboard.contrib.custom.middleware.ContribMiddleware',
)

# Add user login statistics for admin
AUTHENTICATION_BACKENDS = (
    'openstack_dashboard.contrib.custom.animbus_backend.AnimbusKeystoneBackend',
)

INSTALLED_APPS = list(INSTALLED_APPS)
INSTALLED_APPS.append('openstack_dashboard.contrib.custom')

# Reset locale paths
LOCALE_PATHS = [
    os.path.abspath(os.path.join(ROOT_PATH, '..', 'horizon/locale')),
    os.path.abspath(os.path.join(ROOT_PATH, 'locale')),
]

# Contrib settings

# DB CONNECTION
CONNECTION = "mysql+pymysql://root:IHTofpOnkfHtuz4lr8Wbr27199VxcCDP7jSjsBaw@%s/animbus" % 172.16.214.112

# The OPENSTACK_HEAT_STACK settings can be used to disable password
# field required while launching the stack.
OPENSTACK_HEAT_STACK = {
    'enable_user_pass': False,
}

EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_USE_TLS = True
EMAIL_DIR = os.path.join(ROOT_PATH, "themes/contrib/templates/email")
DOMAIN_NAME = None
ADMIN_TOKEN = 'b2930c627e8543e892392aacfd705e5d'

RELEASE_VERSION = {
    'version': 'animbus-5.6.0',
    'os_version': 'Ocata'
}

SECURITY_GROUP_RULES.pop('all_tcp', None)
SECURITY_GROUP_RULES.pop('all_udp', None)
SECURITY_GROUP_RULES.pop('all_icmp', None)

REST_API_REQUIRED_SETTINGS.extend([
    'HYPERVISOR_VERSION',
    'HYPERVISOR',
    'NEED_WORKFLOW_ROLE',
    'OPENSTACK_CINDER_FEATURES',
    'OPENSTACK_KEYSTONE_DEFAULT_ROLE',
    'OPENSTACK_KEYSTONE_BACKEND',
    'OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT',
    'OPENSTACK_NEUTRON_NETWORK',
    'RELEASE_VERSION',
    'OPENSTACK_IMAGE_OS',
    'SECURITY_GROUP_RULES',
    'VOLUME_SIZE_LIMIT',
    'SYSTEM_ROLES'
])

NEED_WORKFLOW_ROLE = 'workflow'

SYSTEM_PROJECTS = ["service", "services"]

SYSTEM_USERS = [
    'heat_domain_admin',
    'horizon',
    'zabbix',
    'ceph_rgw',
    'ceilometer',
    'magnum_trustee_domain_admin'
]

SYSTEM_ROLES = [
    "_member_",
    "admin",
    "domain_admin",
    "member",
    "heat_stack_owner",
    "heat_stack_user",
    "workflow"
]

SITE_BRANDING = 'Animbus Cloud Management Platform'

OPENSTACK_IMAGE_OS = [
    'centos',
    'ubuntu',
    'fedora',
    'windows',
    'debian',
    'coreos',
    'arch',
    'freebsd',
    'others'
]

POLICY_FILES['identity'] = 'policy.v3cloudsample.json'

OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True

VOLUME_SIZE_LIMIT = 1000

DEFAULT_PANKO_API_RETURN_LIMIT = 1000
ANIMBUS_PROJECT_NAME = 'service'
ANIMBUS_USER_NAME = "horizon"
ANIMBUS_USER_PASSWORD = "pQRHKJ6IzjaeaZ9d4GuGxbupWGcxaD8HtEXaHH3H"
