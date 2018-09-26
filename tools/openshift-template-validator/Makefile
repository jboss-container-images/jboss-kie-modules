GO_EXECUTABLE ?= go
DIST_DIR = $(shell echo ${GOPATH}/bin)
SRC_DIR = $(shell pwd)
VERSION ?= $(shell git describe --tags)
VERSION_INCODE = $(shell perl -ne '/^var version.*"([^"]+)".*$$/ && print "v$$1\n"' cli/main.go)

build:
	${GO_EXECUTABLE} build -o openshift-template-validator-linux-amd64 -ldflags "-X main.version=${VERSION}" main.go
	GOOS=windows GOARCH=amd64 ${GO_EXECUTABLE} build -o openshift-template-validator-amd64.exe -ldflags "-X main.version=${VERSION}" main.go

install: build
	install -m 755 -D ${SRC_DIR}/openshift-template-validator-linux-amd64 ${DIST_DIR}/
	install -m 755 -D ${SRC_DIR}/openshift-template-validator-amd64.exe ${DIST_DIR}/

clean:
	rm -rfv ${DIST_DIR}/openshift-template-validator-linux-amd64 ${SRC_DIR}/openshift-template-validator-linux-amd64
	rm -rfv ${DIST_DIR}/openshift-template-validator-amd64.exe ${SRC_DIR}/openshift-template-validator-amd64.exe