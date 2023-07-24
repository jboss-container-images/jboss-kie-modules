module github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator

go 1.17

require (
	github.com/asaskevich/govalidator v0.0.0-20180315120708-ccb8e960c48f
	github.com/openshift/api v0.0.0-20200312145924-779a333deb13
	github.com/openshift/origin v3.11.0+incompatible
	github.com/stretchr/testify v1.4.0
	github.com/urfave/cli v1.20.0
	gopkg.in/yaml.v2 v2.2.8
	k8s.io/api v0.19.0-rc.2
	k8s.io/apimachinery v0.19.0-rc.2
	k8s.io/kubernetes v1.12.0-alpha.0.0.20190501052907-9016740a6ffe
)

require (
	github.com/blang/semver v3.5.2-0.20180723201105-3c1074078d32+incompatible // indirect
	github.com/certifi/gocertifi v0.0.0-20180905225744-ee1a9a0726d2 // indirect
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/docker/distribution v2.8.2+incompatible // indirect
	github.com/docker/docker v20.10.24+incompatible // indirect
	github.com/docker/go-connections v0.3.0 // indirect
	github.com/docker/go-units v0.3.2-0.20170127094116-9e638d38cf69 // indirect
	github.com/evanphx/json-patch v0.5.2 // indirect
	github.com/fatih/camelcase v1.0.0 // indirect
	github.com/getsentry/raven-go v0.0.0-20171206001108-32a13797442c // indirect
	github.com/ghodss/yaml v1.0.0 // indirect
	github.com/gogo/protobuf v1.3.2 // indirect
	github.com/golang/glog v0.0.0-20160126235308-23def4e6c14b // indirect
	github.com/golang/protobuf v1.4.2 // indirect
	github.com/google/go-cmp v0.5.9 // indirect
	github.com/google/gofuzz v1.0.0 // indirect
	github.com/googleapis/gnostic v0.4.1 // indirect
	github.com/gregjones/httpcache v0.0.0-20190611155906-901d90724c79 // indirect
	github.com/hashicorp/golang-lru v0.0.0-20160207214719-a0d98a5f2880 // indirect
	github.com/imdario/mergo v0.0.0-20141206190957-6633656539c1 // indirect
	github.com/inconshreveable/mousetrap v1.0.0 // indirect
	github.com/json-iterator/go v1.1.10 // indirect
	github.com/konsorten/go-windows-terminal-sequences v1.0.3 // indirect
	github.com/modern-go/concurrent v0.0.0-20180306012644-bacd9c7ef1dd // indirect
	github.com/modern-go/reflect2 v1.0.1 // indirect
	github.com/onsi/ginkgo v1.11.0 // indirect
	github.com/onsi/gomega v1.7.0 // indirect
	github.com/opencontainers/go-digest v1.0.0-rc1 // indirect
	github.com/opencontainers/image-spec v1.0.0-rc6.0.20170604055404-372ad780f634 // indirect
	github.com/openshift/client-go v0.0.0-20180830153425-431ec9a26e50 // indirect
	github.com/openshift/library-go v0.0.0-20180828150415-0b8367a46798 // indirect
	github.com/openshift/source-to-image v1.1.12-0.20181024142939-d7dca853b2f3 // indirect
	github.com/peterbourgon/diskv v2.0.1+incompatible // indirect
	github.com/pkg/errors v0.9.1 // indirect
	github.com/pkg/profile v1.2.2-0.20180809112205-057bc52a47ec // indirect
	github.com/pmezard/go-difflib v1.0.0 // indirect
	github.com/sirupsen/logrus v1.6.0 // indirect
	github.com/spf13/afero v1.2.2 // indirect
	github.com/spf13/cobra v1.0.0 // indirect
	github.com/spf13/pflag v1.0.5 // indirect
	golang.org/x/crypto v0.1.0 // indirect
	golang.org/x/net v0.7.0 // indirect
	golang.org/x/sys v0.5.0 // indirect
	golang.org/x/term v0.5.0 // indirect
	golang.org/x/text v0.7.0 // indirect
	golang.org/x/time v0.0.0-20190308202827-9d24e82272b4 // indirect
	google.golang.org/protobuf v1.23.0 // indirect
	gopkg.in/inf.v0 v0.9.0 // indirect
	gopkg.in/square/go-jose.v2 v2.6.0 // indirect
	gopkg.in/yaml.v1 v1.0.0-20140924161607-9f9df34309c0 // indirect
	gotest.tools/v3 v3.5.0 // indirect
	k8s.io/apiextensions-apiserver v0.0.0-20180718013825-06dfdaae5c2b // indirect
	k8s.io/apiserver v0.0.0-20180718002855-8b122ec9e3bb // indirect
	k8s.io/client-go v0.19.0-rc.2 // indirect
	k8s.io/kube-aggregator v0.0.0-20180718003945-89cd614e9090 // indirect
	k8s.io/kube-openapi v0.0.0-20200427153329-656914f816f9 // indirect
	vbom.ml/util v0.0.0-20160121211510-db5cfe13f5cc // indirect
)

replace (
	k8s.io/api => k8s.io/api v0.0.0-20180712090710-2d6f90ab1293
	k8s.io/apiextensions-apiserver => k8s.io/apiextensions-apiserver v0.0.0-20180718013825-06dfdaae5c2b // indirect
	k8s.io/apimachinery => k8s.io/apimachinery v0.0.0-20180621070125-103fd098999d
	k8s.io/apiserver => k8s.io/apiserver v0.0.0-20180718002855-8b122ec9e3bb // indirect
	k8s.io/client-go => k8s.io/client-go v0.0.0-20180718001006-59698c7d9724 // indirect
	k8s.io/kube-aggregator => k8s.io/kube-aggregator v0.0.0-20180718003945-89cd614e9090 // indirect
	k8s.io/kube-openapi => k8s.io/kube-openapi v0.0.0-20180531204156-8a9b82f00b3a // indirect
)
