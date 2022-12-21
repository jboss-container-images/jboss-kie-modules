@ibm-bamoe/bamoe-kieserver-rhel8
@ibm-bamoe/bamoe-businesscentral-rhel8
@ibm-bamoe/bamoe-businesscentral-monitoring-rhel8
@ibm-bamoe/bamoe-dashbuilder-rhel8
@ibm-bamoe/bamoe-controller-rhel8
Feature: IBM BAMOE common tests

  Scenario: Ensure the openjdk8 packages are not installed on container.
    When container is started with command bash
    Then run sh -c '/usr/bin/rpm -q java-1.8.0-openjdk-devel || true' in container and check its output contains package java-1.8.0-openjdk-devel is not installed
     And run sh -c '/usr/bin/rpm -q java-1.8.0-openjdk-headless || true' in container and check its output for package java-1.8.0-openjdk-headless is not installed
     And run sh -c '/usr/bin/rpm -q java-1.8.0-openjdk || true' in container and check its output for package java-1.8.0-openjdk is not installed

  Scenario: Ensure the openjdk17 packages are not installed on container, it is pulled by maven 3.8+
    When container is started with command bash
    Then run sh -c '/usr/bin/rpm -q java-17-openjdk-devel || true' in container and check its output contains package java-17-openjdk-devel is not installed
    And run sh -c '/usr/bin/rpm -q java-17-openjdk-headless || true' in container and check its output for package java-17-openjdk-headless is not installed
    And run sh -c '/usr/bin/rpm -q java-17-openjdk || true' in container and check its output for package java-17-openjdk is not installed

  Scenario: KIECLOUD-274 Prepare PAM/DM images to accept the logger category configuration
    When container is started with env
      | variable          | value                                            |
      | LOGGER_CATEGORIES | com.my.package:TRACE, com.my.other.package:TRACE |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <logger category="com.my.package">
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <logger category="com.my.other.package">
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <level name="TRACE"/>

  Scenario: [KIECLOUD-520] - Make sure the jmx_prometheus_agent is on the desired version
    When container is started with command bash
    Then run sh -c 'test -f /opt/jboss/container/prometheus/jmx_prometheus_javaagent-0.3.2.redhat-00003.jar && echo all good' in container and check its output for all good
    And run sh -c 'md5sum /opt/jboss/container/prometheus/jmx_prometheus_javaagent-0.3.2.redhat-00003.jar' in container and check its output for 8b3af39995b113baf35e53468bad7aae  /opt/jboss/container/prometheus/jmx_prometheus_javaagent-0.3.2.redhat-00003.jar

  Scenario: Make sure the logger pattern is properly configured with a custom pattern
    When container is started with env
      | variable          | value                                           |
      | LOGGER_PATTERN    | %d{yyyy-MM-dd HH:mm:ss.SSS} %-5p [%c{1}] %m%n   |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <pattern-formatter pattern="%d{yyyy-MM-dd HH:mm:ss.SSS} %-5p [%c{1}] %m%n"/>

  Scenario: Make sure the logger pattern is properly configured with a defaut pattern
    When container is started with env
      | variable          | value                                             |
      | LOGGER_PATTERN    | %K{level}%d{HH:mm:ss,SSS} %-5p [%c] (%t) %s%e%n   |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <pattern-formatter pattern="%K{level}%d{HH:mm:ss,SSS} %-5p [%c] (%t) %s%e%n"/>

  Scenario: [KIECLOUD-592] - Verify JBoss contains only the needed files and folders
     When container is started with command bash
     Then run sh -c "[ ! -d "$JBOSS_HOME/domain/" ] && echo Directory domain DOES NOT exists." in container and check its output for domain DOES NOT exists
     Then run sh -c "[ ! -d "$JBOSS_HOME/migration/" ] && echo Directory migration DOES NOT exists." in container and check its output for migration DOES NOT exists
     Then run sh -c "[ -d "$JBOSS_HOME/.installation/" ]  && [ $(ls -1 $JBOSS_HOME/.installation/* 2>/dev/null | wc -l) -eq 0 ] &&  echo Directory .installation is empty." in container and check its output for .installation is empty.
     Then run sh -c "[ ! -d "$JBOSS_HOME/bin/init.d/" ] && echo Directory init.d DOES NOT exists." in container and check its output for init.d DOES NOT exists
     Then run sh -c "[ $(ls -1 $JBOSS_HOME/bin/*.bat 2>/dev/null | wc -l) -eq 0 ] && echo Success no BAT files" in container and check its output for Success no BAT files
     Then run sh -c "[ $(ls -1 $JBOSS_HOME/bin/*.ps1 2>/dev/null | wc -l) -eq 0 ] && echo Success no PS1 files" in container and check its output for Success no PS1 files
     Then run sh -c "[ $(ls -1 $JBOSS_HOME/bin/domain* 2>/dev/null | wc -l) -eq 0 ] && echo Success no domain files" in container and check its output for Success no domain files
     Then run sh -c "[ $(ls -1 $JBOSS_HOME/standalone/configuration/standalone-*.xml 2>/dev/null | wc -l) -eq 1 ] && echo Deleted files successfully" in container and check its output for Deleted files successfully
     Then run sh -c "[ -f $JBOSS_HOME/standalone/configuration/standalone-openshift.xml ] && echo Standalone Openshift is still there" in container and check its output for Standalone Openshift is still there