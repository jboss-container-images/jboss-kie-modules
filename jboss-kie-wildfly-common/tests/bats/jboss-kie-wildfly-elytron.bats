#!/usr/bin/env bats

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
export CONFIG_FILE=${JBOSS_HOME}/standalone/configuration/standalone-openshift.xml
mkdir -p $JBOSS_HOME/standalone/configuration
mkdir -p $JBOSS_HOME/bin/launch

cp $BATS_TEST_DIRNAME/../../../tests/bats/common/launch-common.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../tests/bats/common/logging.bash $JBOSS_HOME/bin/launch/logging.sh
cp $BATS_TEST_DIRNAME/../../../jboss-eap-config-openshift/EAP7.4.0/added/standalone-openshift.xml $JBOSS_HOME/standalone/configuration/standalone-openshift.xml

source $BATS_TEST_DIRNAME/../../added/launch/jboss-kie-wildfly-elytron.sh

teardown() {
    rm -rf $JBOSS_HOME
}

@test "[KIE Server] test if the default kie-fs-realm is correctly added for rhpam" {
    export JBOSS_PRODUCT=rhpam-kieserver

    configure_kie_fs_realm

    expected="<filesystem-realm name=\"KieFsRealm\">
                    <file path=\"/opt/kie/data/kie-fs-realm-users\"/>                </filesystem-realm>"
    result=$(xmllint --xpath "//*[local-name()='filesystem-realm']" $CONFIG_FILE)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    echo "expected_role_decoder: ${expected}"
    echo "result_role_decoder  : ${result}"
    echo "JBOSS_KIE_ARGS: ${JBOSS_KIE_ARGS}"
    [ "${expected}" = "${result}" ]
    [ "${JBOSS_KIE_ARGS}" = " -Dorg.kie.server.services.jbpm.security.filesystemrealm.folder-path=/opt/kie/data/kie-fs-realm-users" ]
}


@test "[KIE Server] test if the default kie-fs-realm is correctly added for rhdm" {
    export JBOSS_PRODUCT=rhdm-kieserver

    configure_kie_fs_realm

    expected="<filesystem-realm name=\"KieFsRealm\">
                    <file path=\"/opt/kie/data/kie-fs-realm-users\"/>                </filesystem-realm>"
    result=$(xmllint --xpath "//*[local-name()='filesystem-realm']" $CONFIG_FILE)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    echo "expected_role_decoder: ${expected}"
    echo "result_role_decoder  : ${result}"
    echo "JBOSS_KIE_ARGS: ${JBOSS_KIE_ARGS}"
    [ "${expected}" = "${result}" ]
    [ "${JBOSS_KIE_ARGS}" = " -Dorg.kie.server.services.jbpm.security.filesystemrealm.folder-path=/opt/kie/data/kie-fs-realm-users" ]
}


@test "test if the default role-decoder is correctly added" {
    configure_role_decoder

    expected="<simple-role-decoder name=\"from-roles-attribute\" attribute=\"role\"/>
<simple-role-decoder name=\"groups-to-roles\" attribute=\"groups\"/>"
    result=$(xmllint --xpath "//*[local-name()='simple-role-decoder']" $CONFIG_FILE)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}


@test "test if the role-decoder is correctly added when Ldap URL is set" {
    AUTH_LDAP_URL="url"

    configure_role_decoder

    expected="<simple-role-decoder name=\"from-roles-attribute\" attribute=\"Roles\"/>
<simple-role-decoder name=\"groups-to-roles\" attribute=\"groups\"/>"
    result=$(xmllint --xpath "//*[local-name()='simple-role-decoder']" $CONFIG_FILE)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [[ "${expected}" =~  ${result} ]]
}


@test "test if the role-decoder is correctly added when Ldap URL is set with failover enabled" {
    AUTH_LDAP_URL="url"
    AUTH_LDAP_LOGIN_FAILOVER="true"

    configure_role_decoder

    expected="<simple-role-decoder name=\"from-roles-attribute\" attribute=\"Roles\"/>
<simple-role-decoder name=\"from-role-attribute\" attribute=\"role\"/>
<simple-role-decoder name=\"groups-to-roles\" attribute=\"groups\"/>"
    result=$(xmllint --xpath "//*[local-name()='simple-role-decoder']" $CONFIG_FILE)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [[ "${expected}" =~  ${result} ]]
}

@test "[KIE Server] test if the kie-fs-realm is correctly added with custom directory" {
    export JBOSS_PRODUCT=rhpam-kieserver
    export KIE_ELYTRON_FS_PATH=/tmp/test/kie-fs

    configure_kie_fs_realm

    expected="<filesystem-realm name=\"KieFsRealm\">
                    <file path=\"/tmp/test/kie-fs\"/>                </filesystem-realm>"
    result=$(xmllint --xpath "//*[local-name()='filesystem-realm']" $CONFIG_FILE)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    echo "JBOSS_KIE_ARGS: ${JBOSS_KIE_ARGS}"
    [ "${expected}" = "${result}" ]
    [ "${JBOSS_KIE_ARGS}" = " -Dorg.kie.server.services.jbpm.security.filesystemrealm.folder-path=/tmp/test/kie-fs" ]
}

@test "[WORKBENCH] test if the default kie-fs-realm is correctly added" {
    export JBOSS_PRODUCT=rhpam-businesscentral
    configure_kie_fs_realm

    expected="<filesystem-realm name=\"KieFsRealm\">
                    <file path=\"/opt/kie/data/kie-fs-realm-users\"/>                </filesystem-realm>"
    result=$(xmllint --xpath "//*[local-name()='filesystem-realm']" $CONFIG_FILE)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    echo "JBOSS_KIE_ARGS: ${JBOSS_KIE_ARGS}"
    [ "${expected}" = "${result}" ]
    [ "${JBOSS_KIE_ARGS}" = " -Dorg.uberfire.ext.security.management.wildfly.filesystem.folder-path=/opt/kie/data/kie-fs-realm-users -Dorg.uberfire.ext.security.management.wildfly.cli.folderPath=/opt/kie/data/kie-fs-realm-users" ]
}

@test "[WORKBENCH] test if the kie-fs-realm is correctly added with custom directory" {
    export JBOSS_PRODUCT=rhpam-businesscentral-monitoring
    export KIE_ELYTRON_FS_PATH=/tmp/test/kie-fs

    configure_kie_fs_realm

    expected="<filesystem-realm name=\"KieFsRealm\">
                    <file path=\"/tmp/test/kie-fs\"/>                </filesystem-realm>"
    result=$(xmllint --xpath "//*[local-name()='filesystem-realm']" $CONFIG_FILE)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    echo "JBOSS_KIE_ARGS: ${JBOSS_KIE_ARGS}"
    [ "${expected}" = "${result}" ]
    [ "${JBOSS_KIE_ARGS}" = " -Dorg.uberfire.ext.security.management.wildfly.filesystem.folder-path=/tmp/test/kie-fs -Dorg.uberfire.ext.security.management.wildfly.cli.folderPath=/tmp/test/kie-fs" ]
}

@test "[DASHBUILDER] test if the kie-fs-realm is correctly added with custom directory" {
    export JBOSS_PRODUCT=rhpam-dashbuilder
    export KIE_ELYTRON_FS_PATH=/tmp/test/kie-fs

    configure_kie_fs_realm

    expected="<filesystem-realm name=\"KieFsRealm\">
                    <file path=\"/tmp/test/kie-fs\"/>                </filesystem-realm>"
    result=$(xmllint --xpath "//*[local-name()='filesystem-realm']" $CONFIG_FILE)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    echo "JBOSS_KIE_ARGS: ${JBOSS_KIE_ARGS}"
    [ "${expected}" = "${result}" ]
    [ "${JBOSS_KIE_ARGS}" = " -Dorg.uberfire.ext.security.management.wildfly.filesystem.folder-path=/tmp/test/kie-fs -Dorg.uberfire.ext.security.management.wildfly.cli.folderPath=/tmp/test/kie-fs" ]
}

@test "test if the correct default application domain is set on the config file" {
    update_security_domain

    expected="<application-security-domain name=\"other\" security-domain=\"ApplicationDomain\"/>
<application-security-domain name=\"other\" security-domain=\"ApplicationDomain\"/>"
    result=$(xmllint --xpath "//*[local-name()='application-security-domain']" $CONFIG_FILE)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}


@test "test if the correct sso application domain is set on the config file" {
    export SSO_URL="http://test"
    update_security_domain

    expected="<application-security-domain name=\"other\" security-domain=\"KeycloakDomain\"/>
<application-security-domain name=\"other\" http-authentication-factory=\"keycloak-http-authentication\"/>"
    result=$(xmllint --xpath "//*[local-name()='application-security-domain']" $CONFIG_FILE)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}


@test "test if the kie_git_config file is correctly generated" {
    export JBOSS_PRODUCT="rhpam-businesscentral"
    export SSO_URL="https://test"
    export SSO_SECRET="web-secret"
    export SSO_REALM="sso-realm"
    configure_business_central_kie_git_config

    expected="{
    \"realm\": \"sso-realm\",
    \"auth-server-url\": \"https://test\",
    \"ssl-required\": \"external\",
    \"resource\": \"kie-git\",
    \"credentials\": {
        \"secret\": \"web-secret\"
    }
}"

    result=$(cat ${JBOSS_HOME}/kie_git_config.json)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}


@test "test if the kie_git_config file is correctly generated with public key" {
    export JBOSS_PRODUCT="rhpam-businesscentral"
    export SSO_URL="https://test"
    export SSO_SECRET="web-secret"
    export SSO_REALM="sso-realm"
    export SSO_PUBLIC_KEY="some-random-key"
    configure_business_central_kie_git_config

    expected="{
    \"realm\": \"sso-realm\",
    \"realm-public-key\": \"some-random-key\",
    \"auth-server-url\": \"https://test\",
    \"ssl-required\": \"external\",
    \"resource\": \"kie-git\",
    \"credentials\": {
        \"secret\": \"web-secret\"
    }
}"

    result=$(cat ${JBOSS_HOME}/kie_git_config.json)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]

}


@test "test if the kie_git_config file is correctly generated with public key for decisioncentral" {
    export JBOSS_PRODUCT="rhdm-decisioncentral"
    export SSO_URL="https://test"
    export SSO_SECRET="web-secret"
    export SSO_REALM="sso-realm"
    export SSO_PUBLIC_KEY="some-random-key"
    configure_business_central_kie_git_config

    expected="{
    \"realm\": \"sso-realm\",
    \"realm-public-key\": \"some-random-key\",
    \"auth-server-url\": \"https://test\",
    \"ssl-required\": \"external\",
    \"resource\": \"kie-git\",
    \"credentials\": {
        \"secret\": \"web-secret\"
    }
}"

    result=$(cat ${JBOSS_HOME}/kie_git_config.json)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]

}


@test "test if the kie_git_config is configured if custom file is provided" {
    export JBOSS_PRODUCT="rhpam-businesscentral"
    mkdir ${JBOSS_HOME}/kie &2> /dev/null
    KIE_GIT_CONFIG_PATH="${JBOSS_HOME}/kie/my_git_kie_config.json"
    touch ${KIE_GIT_CONFIG_PATH}
    export SSO_URL="https://test"

    configure_business_central_kie_git_config

    echo "JBOSS_KIE_ARGS: ${JBOSS_KIE_ARGS}"
    [ "${JBOSS_KIE_ARGS}" = " -Dorg.uberfire.ext.security.keycloak.keycloak-config-file=/tmp/jboss_home/kie/my_git_kie_config.json" ]
}


@test "test elytron ldap configuration dir-context without url" {
    run configure_elytron_ldap_auth

    echo "output: "${output}

    [ "$output" = "[INFO]AUTH_LDAP_URL not set. Skipping LDAP integration..." ]
}


@test "test elytron ldap configuration dir-context" {
    AUTH_LDAP_URL="ldap://test:12345"
    AUTH_LDAP_BIND_DN="uid=admin,ou=system"
    AUTH_LDAP_BIND_CREDENTIAL="my-password"

    configure_elytron_ldap_auth

    expected="<dir-contexts>
                <dir-context name=\"KIELdapDC\" url=\"ldap://test:12345\" principal=\"uid=admin,ou=system\">
                    <credential-reference clear-text=\"my-password\"/>
                </dir-context>
            </dir-contexts>"

    result="$(xmllint --xpath "//*[local-name()='dir-contexts']" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]

}


@test "test elytron ldap configuration dir-context with search limit timeout" {
    AUTH_LDAP_URL="ldap://test:12345"
    AUTH_LDAP_BIND_DN="uid=admin,ou=system"
    AUTH_LDAP_BIND_CREDENTIAL="my-password"
    AUTH_LDAP_SEARCH_TIME_LIMIT="10000"

    configure_elytron_ldap_auth

    expected="<dir-contexts>
                <dir-context name=\"KIELdapDC\" url=\"ldap://test:12345\" read-timeout=\"10000\" principal=\"uid=admin,ou=system\">
                    <credential-reference clear-text=\"my-password\"/>
                </dir-context>
            </dir-contexts>"

    result="$(xmllint --xpath "//*[local-name()='dir-contexts']" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}


@test "test elytron ldap configuration dir-context with search limit timeout and referral mode" {
    AUTH_LDAP_URL="ldap://test:12345"
    AUTH_LDAP_BIND_DN="uid=admin,ou=system"
    AUTH_LDAP_BIND_CREDENTIAL="my-password"
    AUTH_LDAP_SEARCH_TIME_LIMIT="10000"
    AUTH_LDAP_REFERRAL_MODE="ignore"

    configure_elytron_ldap_auth

    expected="<dir-contexts>
                <dir-context name=\"KIELdapDC\" url=\"ldap://test:12345\" read-timeout=\"10000\" referral-mode=\"ignore\" principal=\"uid=admin,ou=system\">
                    <credential-reference clear-text=\"my-password\"/>
                </dir-context>
            </dir-contexts>"

    result="$(xmllint --xpath "//*[local-name()='dir-contexts']" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}


@test "test elytron ldap configuration dir-context with search limit timeout and referral mode and using special characters on bind credential" {
    AUTH_LDAP_URL="ldap://test:12345"
    AUTH_LDAP_BIND_DN="uid=admin,ou=system"
    AUTH_LDAP_BIND_CREDENTIAL="P&s\$w1'\"ord"
    AUTH_LDAP_SEARCH_TIME_LIMIT="10000"
    AUTH_LDAP_REFERRAL_MODE="ignore"

    configure_elytron_ldap_auth

    expected="<dir-contexts>
                <dir-context name=\"KIELdapDC\" url=\"ldap://test:12345\" read-timeout=\"10000\" referral-mode=\"ignore\" principal=\"uid=admin,ou=system\">
                    <credential-reference clear-text=\"P&amp;s\$w1'&quot;ord\"/>
                </dir-context>
            </dir-contexts>"

    result="$(xmllint --xpath "//*[local-name()='dir-contexts']" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}


@test "test elytron ldap configuration dir-context with referral mode" {
    AUTH_LDAP_URL="ldap://test:12345"
    AUTH_LDAP_BIND_DN="uid=admin,ou=system"
    AUTH_LDAP_BIND_CREDENTIAL="my-password"
    AUTH_LDAP_REFERRAL_MODE="follow"

    configure_elytron_ldap_auth

    expected="<dir-contexts>
                <dir-context name=\"KIELdapDC\" url=\"ldap://test:12345\" referral-mode=\"follow\" principal=\"uid=admin,ou=system\">
                    <credential-reference clear-text=\"my-password\"/>
                </dir-context>
            </dir-contexts>"

    result="$(xmllint --xpath "//*[local-name()='dir-contexts']" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}


@test "test elytron ldap configuration dir-context with invalid referral mode" {
    AUTH_LDAP_URL="ldap://test:12345"
    AUTH_LDAP_BIND_DN="uid=admin,ou=system"
    AUTH_LDAP_BIND_CREDENTIAL="my-password"
    AUTH_LDAP_REFERRAL_MODE="invalid"

    run configure_elytron_ldap_auth

    expected="<dir-contexts>
                <dir-context name=\"KIELdapDC\" url=\"ldap://test:12345\" principal=\"uid=admin,ou=system\">
                    <credential-reference clear-text=\"my-password\"/>
                </dir-context>
            </dir-contexts>"

    result="$(xmllint --xpath "//*[local-name()='dir-contexts']" $CONFIG_FILE)"

    echo "lines: ${lines[1]}"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
    [[ "${lines[1]}" = "[WARN]Provided referral mode [INVALID] is not valid, ignoring referral mode, the valid ones are FOLLOW IGNORE THROW" ]]
}


@test "test elytron ldap configuration dir-context without bindDn information" {
    AUTH_LDAP_URL="ldap://test:12345"

    configure_elytron_ldap_auth

    expected="<dir-contexts>
                <dir-context name=\"KIELdapDC\" url=\"ldap://test:12345\"/>
          </dir-contexts>"

    result="$(xmllint --xpath "//*[local-name()='dir-contexts']" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]

}


@test "test elytron ldap configuration ldap-realm with identity-mapping and attribute mapping" {
    AUTH_LDAP_URL="ldap://test:12345"
    AUTH_LDAP_BASE_FILTER="(uid={0})"
    AUTH_LDAP_BASE_CTX_DN="ou=people,dc=example,dc=com"
    AUTH_LDAP_ROLE_ATTRIBUTE_ID="cn"
    AUTH_LDAP_ROLE_FILTER="(member={1})"
    AUTH_LDAP_ROLES_CTX_DN="ou=roles,dc=example,dc=com"

    configure_elytron_ldap_auth

    expected="<ldap-realm name=\"KIELdapRealm\" dir-context=\"KIELdapDC\">
                <identity-mapping rdn-identifier=\"(uid={0})\" search-base-dn=\"ou=people,dc=example,dc=com\">
                    <attribute-mapping>
                        <attribute from=\"cn\" to=\"Roles\" filter=\"(member={1})\" filter-base-dn=\"ou=roles,dc=example,dc=com\"/>
                    </attribute-mapping>
                    <!-- ##KIE_LDAP_NEW_IDENTITY_ATTRIBUTES## -->
                    <user-password-mapper from=\"userPassword\" writable=\"true\"/>
                </identity-mapping>
            </ldap-realm>"

    result="$(xmllint --xpath "//*[local-name()='ldap-realm']" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}


@test "test elytron ldap configuration ldap-realm with identity-mapping and attribute mapping with special characters on baseFilter" {
    AUTH_LDAP_URL="ldap://test:12345"
    AUTH_LDAP_BASE_FILTER="(&(mail={0}))(\|(objectclass=dbperson)(objectclass=inetOrgPerson)))"
    AUTH_LDAP_BASE_CTX_DN="ou=people,dc=example,dc=com"
    AUTH_LDAP_ROLE_ATTRIBUTE_ID="cn"
    AUTH_LDAP_ROLE_FILTER="(member={1})"
    AUTH_LDAP_ROLES_CTX_DN="ou=roles,dc=example,dc=com"

    configure_elytron_ldap_auth

    expected="<ldap-realm name=\"KIELdapRealm\" dir-context=\"KIELdapDC\">
                <identity-mapping rdn-identifier=\"(&amp;(mail={0}))(|(objectclass=dbperson)(objectclass=inetOrgPerson)))\" search-base-dn=\"ou=people,dc=example,dc=com\">
                    <attribute-mapping>
                        <attribute from=\"cn\" to=\"Roles\" filter=\"(member={1})\" filter-base-dn=\"ou=roles,dc=example,dc=com\"/>
                    </attribute-mapping>
                    <!-- ##KIE_LDAP_NEW_IDENTITY_ATTRIBUTES## -->
                    <user-password-mapper from=\"userPassword\" writable=\"true\"/>
                </identity-mapping>
            </ldap-realm>"

    result="$(xmllint --xpath "//*[local-name()='ldap-realm']" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}



@test "test elytron ldap configuration ldap-realm with identity-mapping and attribute mapping using recursive search and blank password" {
    AUTH_LDAP_URL="ldap://test:12345"
    AUTH_LDAP_BASE_FILTER="(uid={0})"
    AUTH_LDAP_BASE_CTX_DN="ou=people,dc=example,dc=com"
    AUTH_LDAP_ROLE_ATTRIBUTE_ID="cn"
    AUTH_LDAP_ROLE_FILTER="(member={1})"
    AUTH_LDAP_ROLES_CTX_DN="ou=roles,dc=example,dc=com"
    AUTH_LDAP_RECURSIVE_SEARCH="true"
    AUTH_LDAP_ALLOW_EMPTY_PASSWORDS="true"

    configure_elytron_ldap_auth

    expected="<ldap-realm name=\"KIELdapRealm\" direct-verification=\"true\" allow-blank-password=\"true\" dir-context=\"KIELdapDC\">
                <identity-mapping rdn-identifier=\"(uid={0})\" search-base-dn=\"ou=people,dc=example,dc=com\" use-recursive-search=\"true\">
                    <attribute-mapping>
                        <attribute from=\"cn\" to=\"Roles\" filter=\"(member={1})\" filter-base-dn=\"ou=roles,dc=example,dc=com\"/>
                    </attribute-mapping>
                    <!-- ##KIE_LDAP_NEW_IDENTITY_ATTRIBUTES## -->
                    <user-password-mapper from=\"userPassword\" writable=\"true\"/>
                </identity-mapping>
            </ldap-realm>"

    result="$(xmllint --xpath "//*[local-name()='ldap-realm']" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}


@test "test elytron ldap configuration ldap-realm with identity-mapping and attribute mapping using recursive search and blank password and using role recursion" {
    AUTH_LDAP_URL="ldap://test:12345"
    AUTH_LDAP_BASE_FILTER="(uid={0})"
    AUTH_LDAP_BASE_CTX_DN="ou=people,dc=example,dc=com"
    AUTH_LDAP_ROLE_ATTRIBUTE_ID="cn"
    AUTH_LDAP_ROLE_FILTER="(member={1})"
    AUTH_LDAP_ROLES_CTX_DN="ou=roles,dc=example,dc=com"
    AUTH_LDAP_RECURSIVE_SEARCH="true"
    AUTH_LDAP_ALLOW_EMPTY_PASSWORDS="true"
    AUTH_LDAP_ROLE_RECURSION=true

    configure_elytron_ldap_auth

    expected="<ldap-realm name=\"KIELdapRealm\" direct-verification=\"true\" allow-blank-password=\"true\" dir-context=\"KIELdapDC\">
                <identity-mapping rdn-identifier=\"(uid={0})\" search-base-dn=\"ou=people,dc=example,dc=com\" use-recursive-search=\"true\">
                    <attribute-mapping>
                        <attribute from=\"cn\" to=\"Roles\" filter=\"(member={1})\" filter-base-dn=\"ou=roles,dc=example,dc=com\" role-recursion=\"true\"/>
                    </attribute-mapping>
                    <!-- ##KIE_LDAP_NEW_IDENTITY_ATTRIBUTES## -->
                    <user-password-mapper from=\"userPassword\" writable=\"true\"/>
                </identity-mapping>
            </ldap-realm>"

    result="$(xmllint --xpath "//*[local-name()='ldap-realm']" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}


@test "test if ldap security domain is correctly added" {
    AUTH_LDAP_URL="test"

    configure_ldap_sec_domain

    expected="<security-domain name=\"KIELdapSecurityDomain\" default-realm=\"KIELdapRealm\" permission-mapper=\"default-permission-mapper\">
                    <realm name=\"KIELdapRealm\" role-decoder=\"from-roles-attribute\"/>
                </security-domain>"
    result="$(xmllint --xpath "//*[local-name()='security-domain'][3]" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}


@test "test if ldap security domain is correctly added with failover" {
    AUTH_LDAP_URL="test"
    AUTH_LDAP_LOGIN_FAILOVER="true"

    configure_ldap_sec_domain

    expected="<security-domain name=\"KIELdapWithFailOverSecDomain\" default-realm=\"KIEFailOverRealm\" permission-mapper=\"default-permission-mapper\">
                    <realm name=\"KIEFailOverRealm\" role-decoder=\"kie-aggregate-role-decoder\"/>
                </security-domain>"
    result="$(xmllint --xpath "//*[local-name()='security-domain'][3]" $CONFIG_FILE)"


    configure_role_decoder
    expected_aggregate_role_mapper="<aggregate-role-decoder name=\"kie-aggregate-role-decoder\">
                <role-decoder name=\"from-roles-attribute\"/>
                <role-decoder name=\"from-role-attribute\"/>
            </aggregate-role-decoder>"
    result_aggregate_role_mapper="$(xmllint --xpath "//*[local-name()='aggregate-role-decoder']" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]

    echo "expected_aggregate_role_mapper: ${expected_aggregate_role_mapper}"
    echo "result_aggregate_role_mapper  : ${result_aggregate_role_mapper}"
    [ "${expected_aggregate_role_mapper}" = "${result_aggregate_role_mapper}" ]
}


@test "test if ldap security domain is correctly added with default role mapping" {
    AUTH_LDAP_URL="test"
    AUTH_LDAP_DEFAULT_ROLE="my-default-role"
    AUTH_LDAP_MAPPER_KEEP_MAPPED="true"

    configure_ldap_sec_domain

    expected="<security-domain name=\"KIELdapSecurityDomain\" default-realm=\"KIELdapRealm\" permission-mapper=\"default-permission-mapper\">
                    <realm name=\"KIELdapRealm\" role-decoder=\"from-roles-attribute\" role-mapper=\"kie-ldap-logical-default-role-mapper\"/>
                </security-domain>"
    result="$(xmllint --xpath "//*[local-name()='security-domain'][3]" $CONFIG_FILE)"

    default_map_role_expected="<constant-role-mapper name=\"kie-ldap-role-mapper\">
                    <role name=\"my-default-role\"/>
                </constant-role-mapper>"
    default_map_role_result="$(xmllint --xpath "//*[local-name()='constant-role-mapper'][2]" $CONFIG_FILE)"

    expected_mapped_role_mapper="<mapped-role-mapper name=\"kie-ldap-mapped-roles\" keep-mapped=\"true\" keep-non-mapped=\"true\">
                    <role-mapping from=\"${AUTH_LDAP_DEFAULT_ROLE}\" to=\"${AUTH_LDAP_DEFAULT_ROLE}\"/>
                </mapped-role-mapper>"
    result_mapped_role_mapper="$(xmllint --xpath "//*[local-name()='mapped-role-mapper']" $CONFIG_FILE)"

    expected_logical_role_mapper="<logical-role-mapper name=\"kie-ldap-logical-default-role-mapper\" logical-operation=\"or\" left=\"kie-ldap-mapped-roles\" right=\"kie-ldap-role-mapper\"/>"
    result_logical_role_mapper="$(xmllint --xpath "//*[local-name()='logical-role-mapper']" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]

    echo "default_map_role_expected: ${default_map_role_expected}"
    echo "default_map_role_result  : ${default_map_role_result}"
    [ "${default_map_role_expected}" = "${default_map_role_result}" ]

    echo "expected_mapped_role_mapper: ${expected_mapped_role_mapper}"
    echo "result_mapped_role_mapper  : ${result_mapped_role_mapper}"
    [ "${expected_mapped_role_mapper}" = "${result_mapped_role_mapper}" ]

    echo "expected_logical_role_mapper: ${expected_logical_role_mapper}"
    echo "result_logical_role_mapper  : ${result_logical_role_mapper}"
    [ "${expected_logical_role_mapper}" = "${result_logical_role_mapper}" ]
}


@test "test if ldap security domain is correctly added with default role mapping and failover enabled" {
    AUTH_LDAP_URL="test"
    AUTH_LDAP_DEFAULT_ROLE="my-default-role"
    AUTH_LDAP_LOGIN_FAILOVER="true"
    AUTH_LDAP_MAPPER_KEEP_MAPPED="true"
    AUTH_LDAP_MAPPER_KEEP_NON_MAPPED="true"

    configure_ldap_sec_domain

    expected="<security-domain name=\"KIELdapWithFailOverSecDomain\" default-realm=\"KIEFailOverRealm\" permission-mapper=\"default-permission-mapper\">
                    <realm name=\"KIEFailOverRealm\" role-decoder=\"kie-aggregate-role-decoder\" role-mapper=\"kie-ldap-logical-default-role-mapper\"/>
                </security-domain>"
    result="$(xmllint --xpath "//*[local-name()='security-domain'][3]" $CONFIG_FILE)"

    default_map_role_expected="<constant-role-mapper name=\"kie-ldap-role-mapper\">
                    <role name=\"my-default-role\"/>
                </constant-role-mapper>"
    default_map_role_result="$(xmllint --xpath "//*[local-name()='constant-role-mapper'][2]" $CONFIG_FILE)"

    expected_mapped_role_mapper="<mapped-role-mapper name=\"kie-ldap-mapped-roles\" keep-mapped=\"true\" keep-non-mapped=\"true\">
                    <role-mapping from=\"${AUTH_LDAP_DEFAULT_ROLE}\" to=\"${AUTH_LDAP_DEFAULT_ROLE}\"/>
                </mapped-role-mapper>"
    result_mapped_role_mapper="$(xmllint --xpath "//*[local-name()='mapped-role-mapper']" $CONFIG_FILE)"

    expected_logical_role_mapper="<logical-role-mapper name=\"kie-ldap-logical-default-role-mapper\" logical-operation=\"or\" left=\"kie-ldap-mapped-roles\" right=\"kie-ldap-role-mapper\"/>"
    result_logical_role_mapper="$(xmllint --xpath "//*[local-name()='logical-role-mapper']" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]

    echo "default_map_role_expected: ${default_map_role_expected}"
    echo "default_map_role_result  : ${default_map_role_result}"
    [ "${default_map_role_expected}" = "${default_map_role_result}" ]

    echo "expected_mapped_role_mapper: ${expected_mapped_role_mapper}"
    echo "result_mapped_role_mapper  : ${result_mapped_role_mapper}"
    [ "${expected_mapped_role_mapper}" = "${result_mapped_role_mapper}" ]

     echo "expected_logical_role_mapper: ${expected_logical_role_mapper}"
     echo "result_logical_role_mapper  : ${result_logical_role_mapper}"
     [ "${expected_logical_role_mapper}" = "${result_logical_role_mapper}" ]
}


@test "test if ldap security domain is correctly added with default role mapping and login module enabled" {
    AUTH_LDAP_URL="test"
    AUTH_LDAP_DEFAULT_ROLE="my-default-role"
    AUTH_LDAP_LOGIN_MODULE="optional"
    AUTH_LDAP_MAPPER_KEEP_MAPPED="false"
    AUTH_LDAP_MAPPER_KEEP_NON_MAPPED="true"

    configure_ldap_sec_domain

    expected="<security-domain name=\"KIELdapSecurityDomain\" default-realm=\"KIEDistributedRealm\" permission-mapper=\"default-permission-mapper\">
                    <realm name=\"KIEDistributedRealm\" role-decoder=\"kie-aggregate-role-decoder\" role-mapper=\"kie-ldap-logical-default-role-mapper\"/>
                </security-domain>"
    result="$(xmllint --xpath "//*[local-name()='security-domain'][3]" $CONFIG_FILE)"

    default_map_role_expected="<constant-role-mapper name=\"kie-ldap-role-mapper\">
                    <role name=\"my-default-role\"/>
                </constant-role-mapper>"
    default_map_role_result="$(xmllint --xpath "//*[local-name()='constant-role-mapper'][2]" $CONFIG_FILE)"

    expected_mapped_role_mapper="<mapped-role-mapper name=\"kie-ldap-mapped-roles\" keep-mapped=\"false\" keep-non-mapped=\"true\">
                    <role-mapping from=\"${AUTH_LDAP_DEFAULT_ROLE}\" to=\"${AUTH_LDAP_DEFAULT_ROLE}\"/>
                </mapped-role-mapper>"
    result_mapped_role_mapper="$(xmllint --xpath "//*[local-name()='mapped-role-mapper']" $CONFIG_FILE)"

    expected_logical_role_mapper="<logical-role-mapper name=\"kie-ldap-logical-default-role-mapper\" logical-operation=\"or\" left=\"kie-ldap-mapped-roles\" right=\"kie-ldap-role-mapper\"/>"
    result_logical_role_mapper="$(xmllint --xpath "//*[local-name()='logical-role-mapper']" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]

    echo "default_map_role_expected: ${default_map_role_expected}"
    echo "default_map_role_result  : ${default_map_role_result}"
    [ "${default_map_role_expected}" = "${default_map_role_result}" ]

    echo "expected_mapped_role_mapper: ${expected_mapped_role_mapper}"
    echo "result_mapped_role_mapper  : ${result_mapped_role_mapper}"
    [ "${expected_mapped_role_mapper}" = "${result_mapped_role_mapper}" ]

     echo "expected_logical_role_mapper: ${expected_logical_role_mapper}"
     echo "result_logical_role_mapper  : ${result_logical_role_mapper}"
     [ "${expected_logical_role_mapper}" = "${result_logical_role_mapper}" ]
}


@test "test if the ldap http auth factory is correctly added" {
    AUTH_LDAP_URL="test"

    configure_elytron_http_auth_factory

    expected="<http-authentication-factory name=\"kie-ldap-http-auth\" http-server-mechanism-factory=\"global\" security-domain=\"KIELdapSecurityDomain\">
                    <mechanism-configuration>
                        <mechanism mechanism-name=\"BASIC\">
                            <mechanism-realm realm-name=\"KIELdapRealm\"/>
                        </mechanism>
                        <mechanism mechanism-name=\"FORM\"/>
                    </mechanism-configuration>
                </http-authentication-factory>"
    result="$(xmllint --xpath "//*[local-name()='http-authentication-factory'][1]" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}


@test "test if the get_security_domain function returns the expected value when ldap url is set" {
    AUTH_LDAP_URL="test"
    result=$(get_security_domain)
    expected="KIELdapSecurityDomain"
    echo "result  : ${result}"
    echo "expected: ${expected}"

   [ "${expected}" = "${result}" ]

}


@test "test if the get_security_domain function returns the expected value when ldap url and AUTH_LDAP_LOGIN_FAILOVER=true are set" {
    AUTH_LDAP_URL="test"
    AUTH_LDAP_LOGIN_FAILOVER="true"
    result=$(get_security_domain)
    expected="KIELdapWithFailOverSecDomain"
    echo "result  : ${result}"
    echo "expected: ${expected}"

   [ "${expected}" = "${result}" ]
}


@test "test if the get_security_domain function returns the expected value when ldap url is set and AUTH_LDAP_LOGIN_FAILOVER failover disabled" {
    AUTH_LDAP_URL="test"
    AUTH_LDAP_LOGIN_FAILOVER="invalid"
    result=$(get_security_domain)
    expected="KIELdapSecurityDomain"
    echo "result  : ${result}"
    echo "expected: ${expected}"

   [ "${expected}" = "${result}" ]
}


@test "test if the get_security_domain function returns the expected value when no ldap url is set" {
    result=$(get_security_domain)
    expected="ApplicationDomain"
    echo "result  : ${result}"
    echo "expected: ${expected}"

   [ "${expected}" = "${result}" ]

}


@test "test if the get_security_domain function returns the expected value when sso url is set" {
    SSO_URL="http://sso=url"
    result=$(get_security_domain)
    expected="KeycloakDomain"
    echo "result  : ${result}"
    echo "expected: ${expected}"

   [ "${expected}" = "${result}" ]
}


@test "test if the get_ldap_realm function returns the expected default value" {
    result=$(get_ldap_realm)
    expected="KIELdapRealm"
    echo "result  : ${result}"
    echo "expected: ${expected}"

   [ "${expected}" = "${result}" ]
}


@test "test if the get_ldap_realm function returns the expected value when failover is enabled" {
    AUTH_LDAP_LOGIN_FAILOVER="true"
    result=$(get_ldap_realm)
    expected="KIEFailOverRealm"
    echo "result  : ${result}"
    echo "expected: ${expected}"

   [ "${expected}" = "${result}" ]
}


@test "test if the get_ldap_realm function returns the expected value when optional login is enabled" {
    AUTH_LDAP_LOGIN_MODULE="optional"
    result=$(get_ldap_realm)
    expected="KIEDistributedRealm"
    echo "result  : ${result}"
    echo "expected: ${expected}"

   [ "${expected}" = "${result}" ]
}


@test "test if the correct application domain is set on the config file for ldap" {
    AUTH_LDAP_URL="test"

    update_security_domain

    expected="<application-security-domain name=\"other\" security-domain=\"KIELdapSecurityDomain\"/>
<application-security-domain name=\"other\" security-domain=\"KIELdapSecurityDomain\"/>"
    result=$(xmllint --xpath "//*[local-name()='application-security-domain']" $CONFIG_FILE)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}


@test "test the configure_elytron_role_mapping with property file with keep mapped" {
    AUTH_LDAP_URL="ldap://test"
    AUTH_ROLE_MAPPER_ROLES_PROPERTIES=$JBOSS_HOME/roles.properties
    echo "admin=PowerUser,BillingAdmin" > ${AUTH_ROLE_MAPPER_ROLES_PROPERTIES}
    echo "guest=guest" >> ${AUTH_ROLE_MAPPER_ROLES_PROPERTIES}
    echo "Administrator=admin,kie-server,rest-all" >> ${AUTH_ROLE_MAPPER_ROLES_PROPERTIES}
    echo "controllerUser=kie-server,rest-all" >> ${AUTH_ROLE_MAPPER_ROLES_PROPERTIES}
    AUTH_LDAP_MAPPER_KEEP_MAPPED="true"

    configure_ldap_sec_domain

    expected="<mapped-role-mapper name=\"kie-custom-role-mapper\" keep-mapped=\"true\" keep-non-mapped=\"false\">
                   <role-mapping from=\"admin\" to=\"PowerUser BillingAdmin\"/>
<role-mapping from=\"guest\" to=\"guest\"/>
<role-mapping from=\"Administrator\" to=\"admin kie-server rest-all\"/>
<role-mapping from=\"controllerUser\" to=\"kie-server rest-all\"/>
                </mapped-role-mapper>"
    result=$(xmllint --xpath "//*[local-name()='mapped-role-mapper']" $CONFIG_FILE)

    expected_sec_domain="<security-domain name=\"KIELdapSecurityDomain\" default-realm=\"KIELdapRealm\" permission-mapper=\"default-permission-mapper\">
                    <realm name=\"KIELdapRealm\" role-decoder=\"from-roles-attribute\" role-mapper=\"kie-custom-role-mapper\"/>
                </security-domain>"
    result_sec_domain="$(xmllint --xpath "//*[local-name()='security-domain'][3]" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]

    echo "expected_sec_domain: ${expected_sec_domain}"
    echo "result_sec_domain  : ${result_sec_domain}"
    [ "${expected_sec_domain}" = "${result_sec_domain}" ]
}

@test "test the configure_elytron_role_mapping with property file with keep mapped and non mapped" {
    AUTH_LDAP_URL="ldap://test"
    AUTH_ROLE_MAPPER_ROLES_PROPERTIES=$JBOSS_HOME/roles.properties
    echo "admin=PowerUser,BillingAdmin" > ${AUTH_ROLE_MAPPER_ROLES_PROPERTIES}
    echo "guest=guest" >> ${AUTH_ROLE_MAPPER_ROLES_PROPERTIES}
    echo "Administrator=admin,kie-server,rest-all" >> ${AUTH_ROLE_MAPPER_ROLES_PROPERTIES}
    echo "controllerUser=kie-server,rest-all" >> ${AUTH_ROLE_MAPPER_ROLES_PROPERTIES}
    AUTH_LDAP_MAPPER_KEEP_MAPPED="true"
    AUTH_LDAP_MAPPER_KEEP_NON_MAPPED="true"

    configure_ldap_sec_domain

    expected="<mapped-role-mapper name=\"kie-custom-role-mapper\" keep-mapped=\"true\" keep-non-mapped=\"true\">
                   <role-mapping from=\"admin\" to=\"PowerUser BillingAdmin\"/>
<role-mapping from=\"guest\" to=\"guest\"/>
<role-mapping from=\"Administrator\" to=\"admin kie-server rest-all\"/>
<role-mapping from=\"controllerUser\" to=\"kie-server rest-all\"/>
                </mapped-role-mapper>"
    result=$(xmllint --xpath "//*[local-name()='mapped-role-mapper']" $CONFIG_FILE)

    expected_sec_domain="<security-domain name=\"KIELdapSecurityDomain\" default-realm=\"KIELdapRealm\" permission-mapper=\"default-permission-mapper\">
                    <realm name=\"KIELdapRealm\" role-decoder=\"from-roles-attribute\" role-mapper=\"kie-custom-role-mapper\"/>
                </security-domain>"
    result_sec_domain="$(xmllint --xpath "//*[local-name()='security-domain'][3]" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]

    echo "expected_sec_domain: ${expected_sec_domain}"
    echo "result_sec_domain  : ${result_sec_domain}"
    [ "${expected_sec_domain}" = "${result_sec_domain}" ]
}


@test "test the configure_elytron_role_mapping with without properties file" {
    AUTH_LDAP_URL="ldap://test"
    AUTH_ROLE_MAPPER_ROLES_PROPERTIES="admin=PowerUser,BillingAdmin;guest=guest;Administrator=admin,kie-server,rest-all;controllerUser=kie-server,rest-all"

    configure_ldap_sec_domain

    expected="<mapped-role-mapper name=\"kie-custom-role-mapper\" keep-mapped=\"false\" keep-non-mapped=\"false\">
                   <role-mapping from=\"admin\" to=\"PowerUser BillingAdmin\"/>
<role-mapping from=\"guest\" to=\"guest\"/>
<role-mapping from=\"Administrator\" to=\"admin kie-server rest-all\"/>
<role-mapping from=\"controllerUser\" to=\"kie-server rest-all\"/>
                </mapped-role-mapper>"
    result=$(xmllint --xpath "//*[local-name()='mapped-role-mapper']" $CONFIG_FILE)

    expected_sec_domain="<security-domain name=\"KIELdapSecurityDomain\" default-realm=\"KIELdapRealm\" permission-mapper=\"default-permission-mapper\">
                    <realm name=\"KIELdapRealm\" role-decoder=\"from-roles-attribute\" role-mapper=\"kie-custom-role-mapper\"/>
                </security-domain>"
    result_sec_domain="$(xmllint --xpath "//*[local-name()='security-domain'][3]" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]

    echo "expected_sec_domain: ${expected_sec_domain}"
    echo "result_sec_domain  : ${result_sec_domain}"
    [ "${expected_sec_domain}" = "${result_sec_domain}" ]
}


@test "test the configure_elytron_role_mapping with without properties file with invalid role pattern and with default role mapping" {
    AUTH_LDAP_URL="ldap://test"
    AUTH_LDAP_DEFAULT_ROLE="my-default-role"
    AUTH_LDAP_MAPPER_KEEP_MAPPED="true"
    AUTH_ROLE_MAPPER_ROLES_PROPERTIES="admin=PowerUser,BillingAdmin;guest=guest;Administrator=admin,kie-server,rest-all;controllerUser=kie-server,rest-all;invalid_role_mapping="

    configure_ldap_sec_domain

    expected="<mapped-role-mapper name=\"kie-ldap-mapped-roles\" keep-mapped=\"true\" keep-non-mapped=\"true\">
                    <role-mapping from=\"admin\" to=\"PowerUser BillingAdmin\"/>
<role-mapping from=\"guest\" to=\"guest\"/>
<role-mapping from=\"Administrator\" to=\"admin kie-server rest-all\"/>
<role-mapping from=\"controllerUser\" to=\"kie-server rest-all\"/>
<role-mapping from=\"my-default-role\" to=\"my-default-role\"/>
                </mapped-role-mapper>"
    result=$(xmllint --xpath "//*[local-name()='mapped-role-mapper']" $CONFIG_FILE)

    expected_sec_domain="<security-domain name=\"KIELdapSecurityDomain\" default-realm=\"KIELdapRealm\" permission-mapper=\"default-permission-mapper\">
                    <realm name=\"KIELdapRealm\" role-decoder=\"from-roles-attribute\" role-mapper=\"kie-ldap-logical-default-role-mapper\"/>
                </security-domain>"
    result_sec_domain="$(xmllint --xpath "//*[local-name()='security-domain'][3]" $CONFIG_FILE)"

    expected_logical_role_mapper="<logical-role-mapper name=\"kie-ldap-logical-default-role-mapper\" logical-operation=\"or\" left=\"kie-ldap-mapped-roles\" right=\"kie-ldap-role-mapper\"/>"
    result_logical_role_mapper="$(xmllint --xpath "//*[local-name()='logical-role-mapper']" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]

    echo "expected_sec_domain: ${expected_sec_domain}"
    echo "result_sec_domain  : ${result_sec_domain}"
    [ "${expected_sec_domain}" = "${result_sec_domain}" ]

    echo "expected_logical_role_mapper: ${expected_logical_role_mapper}"
    echo "result_logical_role_mapper  : ${result_logical_role_mapper}"
    [ "${expected_logical_role_mapper}" = "${result_logical_role_mapper}" ]
}


@test "test elytron ldap configuration by adding new identity attributes." {
    AUTH_LDAP_URL="ldap://test:12345"
    AUTH_LDAP_BASE_FILTER="(uid={0})"
    AUTH_LDAP_BASE_CTX_DN="ou=people,dc=example,dc=com"
    AUTH_LDAP_ROLE_ATTRIBUTE_ID="cn"
    AUTH_LDAP_ROLE_FILTER="(member={1})"
    AUTH_LDAP_ROLES_CTX_DN="ou=roles,dc=example,dc=com"
    AUTH_LDAP_RECURSIVE_SEARCH="true"
    AUTH_LDAP_ALLOW_EMPTY_PASSWORDS="true"

    AUTH_LDAP_NEW_IDENTITY_ATTRIBUTES="objectClass=top inetOrgPerson person organizationalPerson otpToken;sn=BlankSurname;cn=BlankCommonName"

    configure_elytron_ldap_auth
    configure_new_identity_attributes

    expected="<ldap-realm name=\"KIELdapRealm\" direct-verification=\"true\" allow-blank-password=\"true\" dir-context=\"KIELdapDC\">
                <identity-mapping rdn-identifier=\"(uid={0})\" search-base-dn=\"ou=people,dc=example,dc=com\" use-recursive-search=\"true\">
                    <attribute-mapping>
                        <attribute from=\"cn\" to=\"Roles\" filter=\"(member={1})\" filter-base-dn=\"ou=roles,dc=example,dc=com\"/>
                    </attribute-mapping>
                    <new-identity-attributes>
                        <attribute name=\"objectClass\" value=\"top inetOrgPerson person organizationalPerson otpToken\"/>
<attribute name=\"sn\" value=\"BlankSurname\"/>
<attribute name=\"cn\" value=\"BlankCommonName\"/>
                    </new-identity-attributes>
                    <user-password-mapper from=\"userPassword\" writable=\"true\"/>
                </identity-mapping>
            </ldap-realm>"

    result="$(xmllint --xpath "//*[local-name()='ldap-realm']" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}


@test "test if the ldap failover is correctly configured" {
    AUTH_LDAP_URL="url"
    AUTH_LDAP_LOGIN_FAILOVER="true"

    configure_ldap_login_failover

    expected="<failover-realm name=\"KIEFailOverRealm\" delegate-realm=\"KIELdapRealm\" failover-realm=\"KieFsRealm\"/>"
    result="$(xmllint --xpath "//*[local-name()='failover-realm']" $CONFIG_FILE)"

    configure_role_decoder
    expected_aggregate_role_mapper="<aggregate-role-decoder name=\"kie-aggregate-role-decoder\">
                <role-decoder name=\"from-roles-attribute\"/>
                <role-decoder name=\"from-role-attribute\"/>
            </aggregate-role-decoder>"
    result_aggregate_role_mapper="$(xmllint --xpath "//*[local-name()='aggregate-role-decoder']" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]

    echo "expected_aggregate_role_mapper: ${expected_aggregate_role_mapper}"
    echo "result_aggregate_role_mapper  : ${result_aggregate_role_mapper}"
    [ "${expected_aggregate_role_mapper}" = "${result_aggregate_role_mapper}" ]
}


@test "test if the ldap optional login module is correctly configured" {
    AUTH_LDAP_URL="url"
    AUTH_LDAP_LOGIN_MODULE="optional"

    configure_ldap_optional_login

    expected="<distributed-realm name=\"KIEDistributedRealm\" realms=\"KIELdapRealm KieFsRealm\"/>"
    result="$(xmllint --xpath "//*[local-name()='distributed-realm']" $CONFIG_FILE)"

    configure_role_decoder
    expected_aggregate_role_mapper="<aggregate-role-decoder name=\"kie-aggregate-role-decoder\">
                <role-decoder name=\"from-roles-attribute\"/>
                <role-decoder name=\"from-role-attribute\"/>
            </aggregate-role-decoder>"
    result_aggregate_role_mapper="$(xmllint --xpath "//*[local-name()='aggregate-role-decoder']" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]

    echo "expected_aggregate_role_mapper: ${expected_aggregate_role_mapper}"
    echo "result_aggregate_role_mapper  : ${result_aggregate_role_mapper}"
    [ "${expected_aggregate_role_mapper}" = "${result_aggregate_role_mapper}" ]
}


@test "test if rhsso custom-realm is correctly added" {
    configure_rhsso_custom_realm

    expected="<custom-realm name=\"KeycloakOIDCRealm\" module=\"org.keycloak.keycloak-wildfly-elytron-oidc-adapter\" class-name=\"org.keycloak.adapters.elytron.KeycloakSecurityRealm\"/>"
    result="$(xmllint --xpath "//*[local-name()='custom-realm']" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}


@test "test if rhsso security-domain is correctly added" {
    configure_rhsso_security_domain

    expected="<security-domain name=\"KeycloakDomain\" default-realm=\"KeycloakOIDCRealm\" permission-mapper=\"default-permission-mapper\" security-event-listener=\"local-audit\">
                        <realm name=\"KeycloakOIDCRealm\"/>
                    </security-domain>"
    result="$(xmllint --xpath "//*[local-name()='security-domain'][3]" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}


@test "test if rhsso constant realm mapper is correctly added" {
    configure_rhsso_constant_realm_mapper

    expected="<constant-realm-mapper name=\"keycloak-oidc-realm-mapper\" realm-name=\"KeycloakOIDCRealm\"/>"
    result="$(xmllint --xpath "//*[local-name()='constant-realm-mapper'][2]" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}


@test "test if rhsso factory mechanism are correctly added" {
    configure_rhsso_aggregate_http_server_mechanism_factory

    expected="<aggregate-http-server-mechanism-factory name=\"keycloak-http-server-mechanism-factory\">
                    <http-server-mechanism-factory name=\"keycloak-oidc-http-server-mechanism-factory\"/>
                    <http-server-mechanism-factory name=\"global\"/>
                </aggregate-http-server-mechanism-factory>"
    result="$(xmllint --xpath "//*[local-name()='aggregate-http-server-mechanism-factory']" $CONFIG_FILE)"

    expected_service_loader="<service-loader-http-server-mechanism-factory name=\"keycloak-oidc-http-server-mechanism-factory\" module=\"org.keycloak.keycloak-wildfly-elytron-oidc-adapter\"/>"
    result_service_loader="$(xmllint --xpath "//*[local-name()='service-loader-http-server-mechanism-factory']" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]

    echo "expected_service_loader: ${expected_service_loader}"
    echo "result_service_loader  : ${result_service_loader}"
    [ "${expected_service_loader}" = "${result_service_loader}" ]
}


@test "test if rhsso http authentication factory is correctly added" {
    SSO_URL="http://sso-url"
    configure_rhsso_http_authentication_factory

    expected="<http-authentication-factory name=\"keycloak-http-authentication\" security-domain=\"KeycloakDomain\" http-server-mechanism-factory=\"keycloak-http-server-mechanism-factory\">
                    <mechanism-configuration>
                        <mechanism mechanism-name=\"KEYCLOAK\">
                            <mechanism-realm realm-name=\"KeycloakOIDCRealm\" realm-mapper=\"keycloak-oidc-realm-mapper\"/>
                        </mechanism>
                    </mechanism-configuration>
                </http-authentication-factory>"
    result="$(xmllint --xpath "//*[local-name()='http-authentication-factory'][3]" $CONFIG_FILE)"

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}