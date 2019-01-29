#!/bin/bash
set -e

# Necessary to permit running under a random uid
for dir in /deployments $JBOSS_HOME $HOME; do
  chown -R jboss:root $dir
  chmod -R g+rwX $dir
done
