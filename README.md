# JBoss KIE Modules

Here are located all CeKit modules, all the modules that will be used to configure and build the images are placed here.
These modules are copied into the container at build time. There are also external dependencies, like jboss-eap-modules,
cct_modules, etc.; all **external** modules can be found on the modules section of the image.yaml file descriptor for each image.

Below, all CeKit modules contained in this repository:


jboss-kie-modules \
├── [jboss-kie-controller](jboss-kie-controller): RHDM/PAM controller specific modules. \
├── [jboss-kie-kieserver](jboss-kie-kieserver): RHDM/PAM Execution Server specific modules. \
├── [jboss-kie-optaweb-common](jboss-kie-optaweb-common): Optaweb common modules. \
├── [jboss-kie-optaweb-employeerostering](jboss-kie-optaweb-employeerostering): Optaweb Employee Rostering specific modules. \
├── [jboss-kie-smartrouter](jboss-kie-smartrouter): RHPAM Smart Router specific modules. \
├── [jboss-kie-wildfly-common](jboss-kie-wildfly-common): Common modules, basically used by all images. \
├── [jboss-kie-workbench](jboss-kie-workbench):  RHDM/PAM Decision/Business Central specific modules. \
├── [os.kieserver.chmod](os.kieserver.chmod): Process/Decision Server module. \
├── [os.kieserver.launch](os.kieserver.launch): Process/Decision Server module. \
├── [os.kieserver.probes](os.kieserver.probes): Process/Decision liveness and readineses probes. \
├── [os.kieserver.s2i](os.kieserver.s2i): Process/Decision Server module. \
├── [os.kieserver.webapp](os.kieserver.webapp): Process/Decision Server module. \
├── [tests](tests): \
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├── [arquillian](tests/arquillian): Integrations tests based on Arquillian Cube (IPS/DS 6.4.x). \
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├── [bats](tests/bats): Common files for Bats tests. \
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└── [features](tests/features): Image tests (behave) \
└── [tools](tools) \
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├── [build-overrides](tools/build-overrides): Tool used to help to perform image builds using nightly, staging, or candidate artifact builds. \
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├── [gen-template-doc](tools/gen-template-doc): Tool that generates the reference documentation from  Application Templates. \
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└── [openshift-template-validator](tools/openshift-template-validator): Tool used to validate the application templates, if you’re going to develop templates, this tool helps to prevent syntax or accidental issues.


### What can be done in this repository?

The iteration with this repo will be only for fixing issues, adding new modules and writing tests.
This repo is used by the [rhdm-7-openshift-image](https://github.com/jboss-container-images/rhdm-7-openshift-image ) and
[rhpam-7-openshift-image](https://github.com/jboss-container-images/rhpam-7-openshift-image). For example,
[here](https://github.com/jboss-container-images/rhpam-7-openshift-image/blob/master/kieserver/image.yaml#L179) the
jboss-kie-module repo is used and in this [line](https://github.com/jboss-container-images/rhpam-7-openshift-image/blob/master/kieserver/image.yaml#L222)
the [jboss-kie-kieserver](jboss-kie-kieserver) is imported and installed in the target image.


## Tests

There are three different kind of tests: bats, arquillian and behave which are described in details in the next topics.


### Running Arquillian tests

The arquillian is a more complete test, which runs a end to end test: reads an application template, deploys it on an
OpenShift Cluster, completes some tasks, like fire rules, start process, etc. then stops the RHDM/PAM and clean up all
the resources created to run the tests (it is only available for bxms 6.4 yet).
All the needed details and info about how to run these tests are described [here](tests/arquillian/kieserver/64/README.md)


### Running Bats tests

To run Bats tests you need to have it installed, to learn more about its installation please visiti this
[link](https://github.com/bats-core/bats-core#installation)

What is Bats tests? From google: *Bats is a TAP-compliant testing framework for Bash. It provides a simple way to verify
that the UNIX programs you write behave as expected. A Bats test file is a Bash script with special syntax for defining
test cases. Under the hood, each test case is just a function with a description.*

In our case we use it to test some functions in our shell scripts to make sure they will work and produce the right
outputs as expected.

The bats tests are generally added to each module under the **tests** directory, i.e. [jboss-kie-wildfly-common](jboss-kie-wildfly-common).

TODO: Note that, just a few of modules contain the bats tests, more tests will be added in the future.


To run the Bats tests, access a module that already have it, i.e. [jboss-kie-wildfly-common](jboss-kie-wildfly-common)
and execute the following command targeting any **\*.bats** file:

```bash
cd jboss-kie-wildfly-common/tests/bats
bats jboss-kie-wildfly-security-ldap.bats
 ✓ do not replace placeholder when URL is not provided
 ✓ replace placeholder by minimum xml content when URL is provided
 ✓ replace placeholder by all LDAP values when provided

3 tests, 0 failures
```


### Running Behave tests

We use the CeKit to run the Behave tests.
To run the behave tests for the specific image i.e. [kie-server image](https://github.com/jboss-container-images/rhpam-7-openshift-image/tree/master/kieserver),
you must be accessed the image's directory you want to test, execute the command:

Supposing the image repository is cloned already, let's execute the **smartrouter** tests:

```bash
cd /home/user/dev/sources/rhpam-7-openshift-image/smartrouter
cekit test -v
2019-03-21 12:32:27,803 cekit        DEBUG    Running version 2.2.6
2019-03-21 12:32:27,804 cekit        DEBUG    Removing dirty directory: 'target/repo'
2019-03-21 12:32:27,850 cekit        INFO     Generating files for docker engine.
2019-03-21 12:32:27,850 cekit        DEBUG    Loading descriptor from path 'image.yaml'.
...
2019-03-21 12:32:39,525 cekit        INFO     Tests collected!
2019-03-21 12:32:39,562 cekit        DEBUG    Running behave in '/data/dev/sources/rhpam-7-openshift-image/smartrouter/target/test'.
@rhpam-7/rhpam75-smartrouter-openshift
Feature: RHPAM Smart Router configuration tests # features/jboss-kie-modules.git-master/rhpam/smartrouter/rhpam-smartrouter.feature:2

  Scenario: Check if image version and release is printed on boot                          # features/jboss-kie-modules.git-master/rhpam/smartrouter/rhpam-smartrouter.feature:5
    When container is ready                                                                # steps/container_steps.py:13 3.692s
    Then container log should contain rhpam-7/rhpam75-smartrouter-openshift image, version # steps/container_steps.py:27
    Then container log should contain rhpam-7/rhpam75-smartrouter-openshift image, version # steps/container_steps.py:27 0.058s
2019-03-21 12:32:44,003 - dock.middleware.container - INFO - Removing container '61fab7c508fdd56f9c86bbc054d8574ca267113f73b3145eee5fb20892bbd50c', 1 try...
2019-03-21 12:32:44,022 - dock.middleware.container - INFO - Container '61fab7c508fdd56f9c86bbc054d8574ca267113f73b3145eee5fb20892bbd50c' removed
...
1 feature passed, 0 failed, 46 skipped
11 scenarios passed, 0 failed, 412 skipped
46 steps passed, 0 failed, 2277 skipped, 0 undefined
Took 12m24.078s
2019-03-21 12:45:06,855 cekit        INFO     Finished!
2019-03-21 12:45:06,855 - cekit - INFO - Finished!
```

Our tests are driven by annotations, that means each feature or scenario are annotated with the, i.e. [image name](https://github.com/jboss-container-images/jboss-kie-modules/blob/master/tests/features/common/kie-kieserver-common.feature#L1)
In this link there are two annotations which means that rhpam and rhdm kieserver images will trigger all tests in that feature file.

Note that, to run the tests, you need to have a previously image that match the image name and version in the
[image.yaml](https://github.com/jboss-container-images/rhpam-7-openshift-image/blob/master/kieserver/image.yaml#L3-L5) file descriptor.


One useful point is, CeKit allow us to run only one tests, very handy when developing a new test or troubleshooting a existing one.
Those tests are annotated with the **@wip** annotation, and to run it.

Example:

```bash
  @wip
  Scenario: Check if JBOSS_HOME is correctly set
    When container is ready
    Then run sh -c 'echo $JBOSS_HOME' in container and check its output for /opt/eap

```

```bash
$ cekit test --test-wip v
...
2019-01-10 18:17:21,815 cekit        INFO     Fetching common steps from 'https://github.com/cekit/behave-test-steps.git'.
2019-01-10 18:17:23,195 cekit        INFO     Tests collected!
@rhpam-7/rhpam73-businesscentral-openshift
Feature: RHPAM Business Central configuration tests # features/jboss-kie-modules/rhpam/businesscentral/rhpam-businesscentral.feature:2

  @wip
  Scenario: Check if JBOSS_HOME is correctly set                                     # features/jboss-kie-modules/rhpam/businesscentral/rhpam-businesscentral.feature:54
    When container is ready                                                          # steps/container_steps.py:13 3.439s
    Then run sh -c 'echo $JBOSS_HOME' in container and check its output for /opt/eap # steps/container_steps.py:234 0.140s
2019-01-10 18:17:28,114 - dock.middleware.container - INFO - Removing container 'ea3e763cc4f886404bbfd3a1b7bb5979512e3afdd3f6d373de15ebbda965cb6f', 1 try...
2019-01-10 18:17:28,138 - dock.middleware.container - INFO - Container 'ea3e763cc4f886404bbfd3a1b7bb5979512e3afdd3f6d373de15ebbda965cb6f' removed

1 feature passed, 0 failed, 94 skipped
1 scenario passed, 0 failed, 757 skipped
2 steps passed, 0 failed, 3698 skipped, 0 undefined
Took 0m3.579s
2019-03-21 18:17:28,165 cekit        INFO     Finished!
2019-03-21 18:17:28,165 - cekit - INFO - Finished!
```
PS: WIP stands for *Work In Progress* and these tests will run in any image.

Note that, to run the tests, the target image needs to be built and available locally.


### Writing a new Behave test

For more information about behave tests please refer this [link](https://behave.readthedocs.io/en/latest/)

With the Cekit extension of behave we can run, practically, any kind of test on the containers, even source to image tests.
There are a few options that you can use to define what action and what kind of validations/verifications your test must do.
The behave test structure looks like:

```bash
Feature my cool feature
    Scenario test my cool feature - it should print Hello and World on logs
  	  Given/when image is built/container is ready
	  Then container log should contain Hello
	  And container log should contain World
```

One feature can have as many scenarios as you want.
But one Scenario can have one action defined by the keywords given or when, the most common options for this are:

 - **Given s2i build {app_git_repo}**
 - **When container is ready**
 - **When container is started with env** \
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;| variable&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;| value |\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;| JBPM_LOOP_LEVEL_DISABLED&nbsp;&nbsp;&nbsp;| true &nbsp;&nbsp;| \
 In this test, we can specify any valid environment variable or a set of them.
 - **When container is started with args**: Most useful when you want to pass some docker argument, i.e. memory limit for the container.

The **Then** clause is used to do your validations, test something, looking for a keyword in the logs, etc.
If you need to validate more than one thing you can add a new line with the **And** keyword, like this example:

```bash
Scenario test my cool feature - it should print Hello and World on logs
  	  Given/when image is built/container is ready
	  Then container log should contain Hello
	   And container log should contain World
	   And container log should not contain World!!
	   And file /opt/eap/standalone/deployments/bar.jar should not exist
```

The most common sentences are:

 - **Then/And file {file} should exist**
 - **Then/And file {file} should not exist**
 - **Then/And s2i build log should not contain {string}**
 - **Then/And run {bash command} in container and check its output for {command_output}**
 - **Then/And container log should contain {string}**
 - **Then/And container log should not contain {string}**


For a complete list of all available sentences please refer the cekit source code:
https://github.com/cekit/behave-test-steps/tree/v1/steps



##### Found a issue?
Please submit a issue [here](https://issues.jboss.org/projects/KIECLOUD) with the tag or send us a email: bsig-cloud@redhat.com.
