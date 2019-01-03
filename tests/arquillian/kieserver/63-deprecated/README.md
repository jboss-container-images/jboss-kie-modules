# CE-Testsuite - Kie Server (Decision Server and Intelligent Process Server)

This testsuite will test all KIE Server 6.3 S2I application templates which are:
 
  -  [decisionserver63-amq-s2i.json](https://github.com/jboss-openshift/application-templates/blob/master/decisionserver/decisionserver63-amq-s2i.json)
  -  [decisionserver63-basic-s2i.json](https://github.com/jboss-openshift/application-templates/blob/master/decisionserver/decisionserver63-basic-s2i.json)
  -  [decisionserver63-https-s2i.json](https://github.com/jboss-openshift/application-templates/blob/master/decisionserver/decisionserver63-https-s2i.json)
  -  [processserver63-amq-mysql-persistent-s2i.json](https://github.com/jboss-openshift/application-templates/blob/master/processserver/processserver63-amq-mysql-persistent-s2i.json)
  -  [processserver63-amq-mysql-s2i.json](https://github.com/jboss-openshift/application-templates/blob/master/processserver/processserver63-amq-mysql-s2i.json)
  -  [processserver63-amq-postgresql-persistent-s2i.json](https://github.com/jboss-openshift/application-templates/blob/master/processserver/processserver63-amq-postgresql-persistent-s2i.json)
  -  [processserver63-amq-postgresql-s2i.json](https://github.com/jboss-openshift/application-templates/blob/master/processserver/processserver63-amq-postgresql-s2i.json)
  -  [processserver63-basic-s2i.json](https://github.com/jboss-openshift/application-templates/blob/master/processserver/processserver63-basic-s2i.json)
  -  [processserver63-mysql-persistent-s2i.json](https://github.com/jboss-openshift/application-templates/blob/master/processserver/processserver63-mysql-persistent-s2i.json)
  -  [processserver63-mysql-s2i.json](https://github.com/jboss-openshift/application-templates/blob/master/processserver/processserver63-mysql-s2i.json)
  -  [processserver63-postgresql-persistent-s2i.json](https://github.com/jboss-openshift/application-templates/blob/master/processserver/processserver63-postgresql-persistent-s2i.json)
  -  [processserver63-postgresql-s2i.json](https://github.com/jboss-openshift/application-templates/blob/master/processserver/processserver63-postgresql-s2i.json)

For all tests, on this case we are using the following quickstart application:

  - [Hellorules](https://github.com/jboss-openshift/openshift-quickstarts/tree/master/decisionserver/hellorules)

This aplication, basically, only prints the salutation of the given Person's name used to *fire-all-rules*. Example:
```java
        person.setName("Filippe Spolti");
        List<Command<?>> commands = new ArrayList<>();
        commands.add((Command<?>) CommandFactory.newInsert(person));
        commands.add((Command<?>) CommandFactory.newFireAllRules());
        commands.add((Command<?>) CommandFactory.newQuery("greetings", "get greeting"));
        return CommandFactory.newBatchExecution(commands, "HelloRulesSession");
```

### How to run the tests
The Ce-Testsuite uses the [ce-arq](https://github.com/jboss-openshift/ce-arq) which is a API that allow us to test our application templates in a running OpenshiftV3 instance. To run the tests you need:
  - Maven 3 or higher
  - Java 7 or higher
  - Openshift V3 or higher
 
The CE-Testsuite is divided by profiles, to enable the Kie Server profile all you need to do is to use the following maven parameter:
```sh
-Pkieserver63
```
###### Required ce-arq parameteres
  - -P**profile_name**
    - -Pkieserver63
  - -Dkubernetes.master=**address of your running OSE instance (master note)**
    - -Dkubernetes.master=https://openshift-master.mydomain.com:8443
  - -Dkubernetes.registry.url=**the registry address running in your ose instance**
    - -Dkubernetes.registry.url=openshift-master.mydomain.com:5001
  - -Ddocker.url=**Docker url address**
    - -Ddocker.url=https://openshift-master.mydomain.com:2375
  - -Drouter.hostIP=**The OSE router IP**
    - -Drouter.hostIP=192.168.1.254
      - You can change this parameter name in the pom.xml

###### Optional ce-arq parameteres
  - -Dtest=**The test class name, if you want to run only one test, otherwise all tests will be executed**
    - -Dtest=DecisionServerAmqTest
  - -Dkubernetes.ignore.cleanup=true **(default is false), It will ignore the resources cleanup, so you can take a look in the used pods to troubleshooting**

> **All those are java parameters, so use -D.**
___

###### Running all tests
For this example we'll consider the IP address 192.168.1.254 for required parameters, Example:
```sh
$ mvn clean package test -Pkieserver63 -Dkubernetes.master=https://192.168.1.254:8443 -Dkubernetes.registry.url=192.168.1.254:5001 -Ddocker.url=http://192.168.1.254:2375 -Drouter.hostIP=192.168.1.254
```
###### Running a specific test and ignoring the cleanup after the tests gets finished
Example:
```sh
$ mvn clean package test -Pkieserver63 -Dkubernetes.master=https://192.168.1.254:8443 -Dkubernetes.registry.url=192.168.1.254:5001 -Ddocker.url=http://192.168.1.254:2375 -Drouter.hostIP=192.168.1.254 -Dtest=DecisionServerAmqTest -Dkubernetes.ignore.cleanup=true
```

#### What this tests cover?
This test covers all basic operations to make sure the docker image generated by the used application templates will work as expected, it will do basic operations against the deployed quickstart, which is:

  - Create a single container and:
    - Test if the container was successfully created and started.
    - Check the Decision Server capability, (BRM).
    - Fire all rules.
Both tests are tested againts all supported ways: using Drools JAVA API, Rest API and AMQ interface.

#### Found an issue?
Please, feel free to report the issue that you found [here](https://github.com/jboss-openshift/ce-testsuite/issues/new).

__For feedbacks please send us an email (cloud-enablement-feedback@redhat.com) and let us know what you are thinking.__ 
