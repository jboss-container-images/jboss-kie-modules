#!/bin/sh

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added
SOURCES_DIR="/tmp/artifacts"

unzip -o "$SOURCES_DIR"/rh-sso-7.5.0-eap7-adapter-dist.zip -d $JBOSS_HOME
unzip -o "$SOURCES_DIR"/rh-sso-7.5.0-saml-eap7-adapter-dist.zip -d $JBOSS_HOME

for dir in $JBOSS_HOME/docs/licenses-rh-sso $JBOSS_HOME/modules/system/add-ons $JBOSS_HOME/bin; do
    chown -R jboss:root $dir
    chmod -R g+rwX $dir
done

