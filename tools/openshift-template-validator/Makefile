SHELL = /bin/bash

GO_EXECUTABLE ?= go
DIST_DIR ?= $(shell echo ${GOPATH}/bin)
SRC_DIR = $(shell pwd)
VERSION ?= $(shell git describe --tags)

build:
	${GO_EXECUTABLE} build -o openshift-template-validator-linux-amd64 -ldflags "-X main.version=${VERSION}" main.go
	GOOS=windows GOARCH=amd64 ${GO_EXECUTABLE} build -o openshift-template-validator-amd64.exe -ldflags "-X main.version=${VERSION}" main.go

install:
	install -m 755 -D ${SRC_DIR}/openshift-template-validator-linux-amd64 ${DIST_DIR}/
	install -m 755 -D ${SRC_DIR}/openshift-template-validator-amd64.exe ${DIST_DIR}/
	cp -v ${SRC_DIR}/bash-completion.sh /etc/bash_completion.d/openshift-template-validator-linux-amd64

clean:
	rm -rfv ${DIST_DIR}/openshift-template-validator-linux-amd64 ${SRC_DIR}/openshift-template-validator-linux-amd64
	rm -rfv ${DIST_DIR}/openshift-template-validator-amd64.exe ${SRC_DIR}/openshift-template-validator-amd64.exe
	rm -rfv /etc/bash_completion.d/openshift-template-validator-linux-amd64
	unset -f _validator_completions