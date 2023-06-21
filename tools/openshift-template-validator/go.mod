module github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator

go 1.17

require (
	github.com/asaskevich/govalidator v0.0.0-20180315120708-ccb8e960c48f
	github.com/openshift/api v0.0.0-20200312145924-779a333deb13
	github.com/openshift/origin v3.11.0+incompatible
	github.com/stretchr/testify v1.2.2-0.20180319223459-c679ae2cc0cb
	github.com/urfave/cli v1.20.0
	gopkg.in/yaml.v2 v2.2.8
	k8s.io/api v0.0.0-20180712090710-2d6f90ab1293
	k8s.io/apimachinery v0.0.0-20180621070125-103fd098999d
	k8s.io/kubernetes v1.12.0-alpha.0.0.20190501052907-9016740a6ffe
)

require (
	github.com/blang/semver v3.5.2-0.20180723201105-3c1074078d32+incompatible // indirect
	github.com/certifi/gocertifi v0.0.0-20180905225744-ee1a9a0726d2 // indirect
	github.com/davecgh/go-spew v1.1.1-0.20170626231645-782f4967f2dc // indirect
	github.com/docker/distribution v2.8.2+incompatible // indirect
	github.com/docker/docker v1.13.2-0.20170601211448-f5ec1e2936dc // indirect
	github.com/docker/go-connections v0.3.0 // indirect
	github.com/docker/go-units v0.3.2-0.20170127094116-9e638d38cf69 // indirect
	github.com/getsentry/raven-go v0.0.0-20171206001108-32a13797442c // indirect
	github.com/ghodss/yaml v0.0.0-20150909031657-73d445a93680 // indirect
	github.com/gogo/protobuf v1.3.2 // indirect
	github.com/golang/glog v0.0.0-20141105023935-44145f04b68c // indirect
	github.com/golang/protobuf v1.1.0 // indirect
	github.com/google/gofuzz v0.0.0-20161122191042-44d81051d367 // indirect
	github.com/googleapis/gnostic v0.0.0-20170729233727-0c5108395e2d // indirect
	github.com/hashicorp/golang-lru v0.0.0-20160207214719-a0d98a5f2880 // indirect
	github.com/imdario/mergo v0.0.0-20141206190957-6633656539c1 // indirect
	github.com/inconshreveable/mousetrap v1.0.0 // indirect
	github.com/json-iterator/go v0.0.0-20180612202835-f2b4162afba3 // indirect
	github.com/modern-go/concurrent v0.0.0-20180306012644-bacd9c7ef1dd // indirect
	github.com/modern-go/reflect2 v0.0.0-20180320133207-05fbef0ca5da // indirect
	github.com/opencontainers/go-digest v0.0.0-20170106003457-a6d0ee40d420 // indirect
	github.com/opencontainers/image-spec v1.0.0-rc6.0.20170604055404-372ad780f634 // indirect
	github.com/openshift/client-go v0.0.0-20180830153425-431ec9a26e50 // indirect
	github.com/openshift/library-go v0.0.0-20180828150415-0b8367a46798 // indirect
	github.com/openshift/source-to-image v1.1.12-0.20181024142939-d7dca853b2f3 // indirect
	github.com/pkg/errors v0.8.0 // indirect
	github.com/pkg/profile v1.2.2-0.20180809112205-057bc52a47ec // indirect
	github.com/sirupsen/logrus v1.0.4-0.20170822132746-89742aefa4b2 // indirect
	github.com/spf13/cobra v0.0.2-0.20180319062004-c439c4fa0937 // indirect
	github.com/spf13/pflag v1.0.1 // indirect
	golang.org/x/crypto v0.0.0-20200622213623-75b288015ac9 // indirect
	golang.org/x/net v0.0.0-20201021035429-f5854403a974 // indirect
	golang.org/x/sys v0.0.0-20220722155257-8c9f86f7a55f // indirect
	golang.org/x/text v0.3.8 // indirect
	golang.org/x/time v0.0.0-20161028155119-f51c12702a4d // indirect
	gopkg.in/inf.v0 v0.9.0 // indirect
	k8s.io/apiextensions-apiserver v0.0.0-20180718013825-06dfdaae5c2b // indirect
	k8s.io/apiserver v0.0.0-20180718002855-8b122ec9e3bb // indirect
	k8s.io/client-go v0.0.0-20180718001006-59698c7d9724 // indirect
	k8s.io/kube-aggregator v0.0.0-20180718003945-89cd614e9090 // indirect
	k8s.io/kube-openapi v0.0.0-20180531204156-8a9b82f00b3a // indirect
)

replace github.com/docker/docker v1.13.2-0.20170601211448-f5ec1e2936dc => github.com/docker/engine v17.12.0-ce-rc1.0.20180718150940-a3ef7e9a9bda+incompatible
