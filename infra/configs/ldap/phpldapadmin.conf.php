<?php
/**
 * phpLDAPadmin Configuration File
 * CyberLab LDAP Management Interface
 */

// Enable debug mode (set to false in production)
$config['debug'] = false;

// Minimum password length
$config['password_min_length'] = 12;

// Require strong passwords (uppercase, lowercase, numbers, special chars)
$config['password_require_special_chars'] = true;

// Admin DN for phpLDAPadmin
$config['login_dn'] = 'cn=admin,dc=cyberlab,dc=local';

// Application name
$config['app_title'] = 'CyberLab LDAP Management';

// Default language
$config['language'] = 'en_US';

// Theme
$config['theme'] = 'default';

// Enable anonymous bind
$config['allow_anonymous_bind'] = false;

// Enable login
$config['login_required'] = true;

// Session timeout (in seconds)
$config['session_timeout'] = 3600;

// Allow changing passwords
$config['allow_password_reset'] = true;

// Redirect HTTPS
$config['force_https'] = true;

// LDAP Server Configuration
$servers = array(
    array(
        'name' => 'CyberLab LDAP',
        'host' => 'openldap',
        'port' => 389,
        'base' => array('dc=cyberlab,dc=local'),
        'auth_type' => 'session',
        'bind_id' => 'cn=admin,dc=cyberlab,dc=local',
        'bind_pass' => '', // Set via environment
        'auto_append_suffix' => true,

        // Display names
        'name_attr' => array('cn','uid'),
        'mail_attr' => 'mail',
        'phone_attr' => 'telephoneNumber',

        // Page settings
        'page_size' => 50,

        // Enable SASL
        'enable_sasl' => false,

        // Denormalization settings
        'user_filter' => '(&(objectClass=inetOrgPerson)(uid=*))',
        'group_filter' => '(&(objectClass=groupOfNames)(cn=*))',

        // Object creation
        'unique_attrs' => array(
            'uid',
            'mail',
            'cn'
        )
    )
);

// Attribute visibility (which attributes to show in the web interface)
$visible_attrs = array(
    'objectClass',
    'cn',
    'uid',
    'mail',
    'telephoneNumber',
    'mobile',
    'sn',
    'givenName',
    'departmentNumber',
    'description',
    'memberOf',
    'createTimestamp',
    'modifyTimestamp',
    'pwdChangedTime',
    'loginTime'
);

// Hidden attributes
$hidden_attrs = array(
    'userPassword',
    'sambaLMPassword',
    'sambaNTPassword',
    'sambaPwdLastSet',
    'pwdChangedTime',
    'entryUUID',
    'entryCSN'
);

// Read-only attributes
$readonly_attrs = array(
    'objectClass',
    'createTimestamp',
    'modifyTimestamp',
    'creatorsName',
    'modifiersName',
    'entryUUID',
    'entryCSN'
);

// Attribute pretty names for display
$attr_display_names = array(
    'objectClass' => 'Object Classes',
    'uid' => 'User ID',
    'mail' => 'Email',
    'telephoneNumber' => 'Phone',
    'sn' => 'Last Name',
    'givenName' => 'First Name',
    'departmentNumber' => 'Department',
    'loginTime' => 'Last Login',
    'pwdChangedTime' => 'Password Changed',
    'memberOf' => 'Member Of Groups'
);

// Template objects (quick-add user/group templates)
$objects = array(
    'user' => array(
        'icon' => 'person.png',
        'template' => array(
            'objectClass' => array('inetOrgPerson', 'organizationalPerson', 'person', 'top'),
            'uid' => 'newuser',
            'cn' => 'New User',
            'sn' => 'User',
            'givenName' => 'New',
            'mail' => 'newuser@cyberlab.local',
            'userPassword' => ''
        )
    ),
    'group' => array(
        'icon' => 'group.png',
        'template' => array(
            'objectClass' => array('groupOfNames', 'top'),
            'cn' => 'newgroup',
            'description' => 'New Group',
            'member' => array()
        )
    ),
    'organizational_unit' => array(
        'icon' => 'folder.png',
        'template' => array(
            'objectClass' => array('organizationalUnit', 'top'),
            'ou' => 'newou',
            'description' => 'New Organizational Unit'
        )
    )
);

// Access control
$config['hide_admin_dn'] = true;
$config['hide_own_dn'] = true;

// Search settings
$config['max_search_results'] = 1000;
$config['search_filter_auto_wildcards'] = true;

// Mass operation settings
$config['mass_change'] = true;
$config['mass_delete'] = false;

// Display settings
$config['show_attribute_values'] = true;
$config['show_binary_attributes'] = false;

// Query configuration
$config['query_filter'] = '(&(uid=*)(objectClass=inetOrgPerson))';

// Logging
$config['enable_logging'] = true;
$config['log_path'] = '/var/log/phpldapadmin/';
$config['log_level'] = 'DEBUG';

?>
