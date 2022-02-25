# OpenShift Template Validator

The openshift-template-validator tool have the purpose to help OpenShift Application Template developers to avoid mistakes
like syntax issues, invalid values for a kind of Object parameter, this version is intended to be used to validate Red Hat's
Products Application Templates, but in a near future, most of the validation will be customizable allowing users to validate
any Application Template according your needs.


#### How to Use

Verify the tool options by executing the following command:

```bash
$ openshift-template-validator-linux-amd64 validate --help
NAME:
   openshift-template-validator-linux-amd64 validate - Validate OpenShift Application Template(s)

USAGE:
   openshift-template-validator-linux-amd64 validate [command options] [arguments...]

DESCRIPTION:
   Validate just one template or a bunch of them, the issues found will be printed, the binary will exit with 0, means success and any value different than 0 means that some issue happened (10 - file or directory not found, 12 - validation issues, 15 - panic)

OPTIONS:
   --file value, -f value               Set the template or imagestream to be validate, can be a local file or a remote valid url with raw content.
   --dir value, -d value                Define a directory to be read, all yaml and json files in the given directory will be validated by the tool.
   --persist, -p                        If set, the validated yaml file be saved on /tmp/<file-name> in the json format.
   --custom-annotation value, -a value  Define a custom annotation to be tested against the target template's annotations, values must be separated by comma ',' with no spaces. The default annotations are [iconClass, openshift.io/display-name, tags, version, description, openshift.io/provider-display-name, template.openshift.io/documentation-url, template.openshift.io/support-url, template.openshift.io/long-description, template.openshift.io/bindable]
   --template-version value, -v value   The template version that will br tested with the target templates, if not provided. (default: "1.2")
   --validate-version, -V               If set, the template version will be validate.
   --verbose, --vv                      Prints detailed log messages
   --strict, -s                         Enable the strict mode, will verify if any required parameter have no value.
   --dump, --du                         Dump all parsed template parameters.
   --disable-defer                      Disable defer which recover from panic for troubleshooting purposes.
```


#### Converting yaml to json

By default, all the validations are done using the JSON format, except for the template parameters which is parsed to a custom struct, one by one before be validated.
If your Application template is in the yaml format and you want to save a json copy of it, just use the flat *--persist*, the json file will be saved on /tmp:

```bash
$ openshift-template-validator-linux-amd64 validate validate -f /sources/rhdm-7-openshift-image/templates/rhdm71-full.yaml --persist
Validating file /sources/rhdm-7-openshift-image/templates/rhdm71-full.yaml -----> No validation issues found.
```

Then, check if the file was generated:

```bash
$ ls -la /tmp/rhdm71-full.json
-rw-r--r--. 1 spolti spolti 21145 Aug 31 12:44 /tmp/rhdm71-full.json
```


#### Verifying custom annotations

By default, there is a few required annotations, which are:

```Go
"iconClass", "openshift.io/display-name", "tags", "version", "description", "openshift.io/provider-display-name",
"template.openshift.io/documentation-url", "template.openshift.io/support-url", "template.openshift.io/long-description", "template.openshift.io/bindable"
```

Beside those template annotations, is possible to provide custom ones, for example:

```bash
$ openshift-template-validator-linux-amd64 validate validate -f /sources/rhdm-7-openshift-image/templates/rhdm71-full.yaml --custom-annotation test,testA,testB
Validating file /sources/rhdm-7-openshift-image/templates/rhdm71-full.yaml
Errors found: {
  "Annotations": [
    "Annotation test was not in the template annotations.",
    "Annotation testA was not in the template annotations.",
    "Annotation testB was not in the template annotations."
  ]
}
```

User can also provide a desired value for the custom annotation by using key=value format, you can also provide custon annotations
with no value that it will be tested too.

```bash
$ openshift-template-validator-linux-amd64 validate -f /data/dev/sources/rhpam-7-openshift-image/templates/rhpam71-authoring.yaml -a value1=one,value2=two,value3=trhee,otherAnnotation
Validating file /data/dev/sources/rhpam-7-openshift-image/templates/rhpam71-authoring.yaml
Errors found: {
  "Annotations": [
    "Annotation value1 was found in the template annotations but does not contain the required value[one].",
    "Annotation value2 was not found in the template annotations.",
    "Annotation value3 was not found in the template annotations.",
    "Annotation otherAnnotation was not found in the template annotations."
  ]
}
```


#### Verifying template version

When releasing a new version of the Application Template, it could be useful to verify if a template has the expected version number, it could be easily done
by setting the flag -V (the default version is 1.0) and -v with the desired version:


```bash
$ openshift-template-validator-linux-amd64validate -f /sources/rhdm-7-openshift-image/templates/rhdm71-full.yaml -V -v alpha01
Validating file /sources/rhdm-7-openshift-image/templates/rhdm71-full.yaml
Errors found: {
  "Annotations": [
    "The provided version does not match the template version. Provided [alpha01] - Template Version: 1.0."
  ]
}
```

#### Template parameters validation

This tool also verifies the template parameters, it will check:
- if the parameter have all the required fields: DisplayName, Description, Name and Required
- if any parameter is required, but not value provided (--strict-mode)
- if all defined parameters are being used in any DeploymentConfig
- if there is no duplicated paremeter

##### Strict mode

The Strict mode will verify if there is a required parameter with no value, example:

```bash
$ openshift-template-validator-linux-amd64 validate -f /sources/rhdm-7-openshift-image/templates/rhdm71-full.yaml
Validating file /sources/rhdm-7-openshift-image/templates/rhdm71-full.yaml -----> No validation issues found.

$ openshift-template-validator-linux-amd64 validate -f /sources/rhdm-7-openshift-image/templates/rhdm71-full.yaml --strict
Validating file /sources/rhdm-7-openshift-image/templates/rhdm71-full.yaml
Errors found: {
  "ObjectsValidation-Processor": [
    "template.parameters[1]: Required value: template.parameters[1]: parameter KIE_ADMIN_USER is required and must be specified"
  ]
}
```


##### Dumping template parameters for troubleshooting

If for some reason the parameters validation failed and you want to verify the parameters, just use the *dump* flag:

```bash
 $ openshift-template-validator-linux-amd64 validate -f /sources/rhdm-7-openshift-image/templates/rhdm71-full.yaml --dump
Validating file /sources/rhdm-7-openshift-image/templates/rhdm71-full.yaml
parameters:
- displayName: Application Name
  description: The name for the application.
  name: APPLICATION_NAME
  value: myapp
  required: true
...
- displayName: KIE Server Container Memory Limit
  description: KIE Server Container memory limit
  name: KIE_SERVER_MEMORY_LIMIT
  value: 1Gi
  required: false
 -----> No validation issues found.

```

#### Multi Template validation

It is also allowed specify a directory with the flag *-d /target/directory/*


#### Validating ImageStreams

This tool also validate ImageStream, for this, the ImageStream kind must be *ImageStreamList*, i.e.:

```yaml
kind: ImageStreamList
apiVersion: v1
metadata:
  name: rhpam78-image-streams
...
```

Then, just run the tool:

```bash
$ openshift-template-validator-linux-amd64 validate -f rhpam78-image-streams.yaml
Validating file rhpam78-image-streams.yaml -----> No validation issues found.
```

#### Troubleshooting

If you trying to validate the template and a similar issue happens:

```bash
$ openshift-template-validator-linux-amd64 validate -f /sources/rhdm-7-openshift-image/templates/rhdm71-full.yaml
Validating file /sources/rhdm-7-openshift-image/templates/rhdm71-full.yaml
Errors found: {
  "PreValidation-12-*v1.DeploymentConfig": [
    "unrecognized type: int32"
  ]
}

```

try to enable the verbose mode with the flag -vv to get more information about the issue:


```bash
$ openshift-template-validator-linux-amd64 validate -f /sources/rhdm-7-openshift-image/templates/rhdm71-full.yaml --vv
Validating file /sources/rhdm-7-openshift-image/templates/rhdm71-full.yaml -> replacing Template apiVersion from v1 to template.openshift.io/v1
Error on converting Unstructured object unrecognized type: int32
A possible error happened on object kind '*v1.DeploymentConfig' and name 'myapp-kieserver' while parsing container ports [{jolokia 0 0  } { 0 0  } { 0 0  }]
recovered from  runtime error: invalid memory address or nil pointer dereference

Errors found: {
  "PreValidation-12-*v1.DeploymentConfig": [
    "unrecognized type: int32"
  ]
}
```

In this case, the issue was a string character in the container port definition on the template:

```yaml
          ports:
          - name: jolokia
            containerPort: 8778s
```


### TODO

- allow user to specify the validations they want to disable, i.e --disable-annotations-check


#### Contributing

The next lines contains all the necessary steps to build this tool from source.


#### Preparing your environment

###### Requirements

- golang 1.16

##### Building


Build:
```bash
$ make
```

The build will generate two binaries:
- openshift-template-validator-linux-amd64
- openshift-template-validator-amd64.exe

Install the binaries on the $GOPATH/bin (make sure you have this path on your $PATH env variable)
```bash
$ make install
```

To clean the binaries
```bash
$ make clean
```

If you have any question, feedback or suggestions to improve, contact us through the email bsig-cloud@redhat.com
