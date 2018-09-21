#!/usr/bin/env bash

if [ -z "$GOPATH" ]; then
    echo "GOPATH not set"
    exit 1
fi
type make
if [ $? != 0 ]; then
    echo "make command not found".
    exit 1
fi
type go
if [ $? != 0 ]; then
    echo "go command not found".
    exit 1
fi
type glide
if [ $? != 0 ]; then
    echo "installing glide"
    curl https://glide.sh/get | sh
fi

echo "manually fetching github.com/openshift/origin"
go get github.com/openshift/origin
mv "${GOPATH}"/src/github.com/openshift/origin/vendor "${GOPATH}"/src/github.com/openshift/origin/_vendor

echo "manually fetching github.com/openshift/source-to-image"
go get github.com/openshift/source-to-image
mv "${GOPATH}"/src/github.com/openshift/source-to-image/vendor "${GOPATH}"/src/github.com/openshift/source-to-image/_vendor


"${GOPATH}"/bin/glide up
"${GOPATH}"/bin/glide install --strip-vendor

# TODO revisit
# Revisit it later to see if if we can rely only on vendor directory, at this moment it is not possible because the project the tool source is inside another repo
# which makes it difficult to use a dependency management tool.
mv $GOPATH/src/github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator/vendor/github.com/openshift/api $GOPATH/src/github.com/openshift/
mv $GOPATH/src/github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator/vendor/github.com/openshift/library-go $GOPATH/src/github.com/openshift/
mv $GOPATH/src/github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator/vendor/github.com/openshift/client-go $GOPATH/src/github.com/openshift/
rm -rf $GOPATH/src/github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator/vendor/github.com/openshift
mv $GOPATH/src/github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator/vendor/github.com/* $GOPATH/src/github.com/
rm -rf $GOPATH/src/github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator/vendor/github.com
mv $GOPATH/src/github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator/vendor/* $GOPATH/src/


echo "Trying to build the openshift-template-validator"
make install
