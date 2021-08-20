@rhpam-7/rhpam-dashbuilder-rhel8
Feature: RHPAM Dashbuilder Runtime configuration tests

  # https://issues.jboss.org/browse/CLOUD-180
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain rhpam-7/rhpam-dashbuilder-rhel8 image, version

  Scenario: Check for product and version environment variables
    When container is started with command bash
    Then run sh -c 'echo $JBOSS_PRODUCT' in container and check its output for rhpam-dashbuilder
     And run sh -c 'echo $RHPAM_DASHBUILDER_VERSION' in container and check its output for 7.12

  Scenario: Verify if the properties were correctly set using DEFAULT MEM RATIO
    When container is started with args
      | arg       | value                                                    |
      | mem_limit | 1073741824                                               |
      | env_json  | {"JAVA_MAX_MEM_RATIO": 80, "JAVA_INITIAL_MEM_RATIO": 25} |
    Then container log should match regex -Xms205m
     And container log should match regex -Xmx819m

  Scenario: Verify if the DEFAULT MEM RATIO properties are overridden with different values
    When container is started with args
      | arg       | value                                                    |
      | mem_limit | 1073741824                                               |
      | env_json  | {"JAVA_MAX_MEM_RATIO": 50, "JAVA_INITIAL_MEM_RATIO": 10} |
    Then container log should match regex -Xms51m
    And container log should match regex -Xmx512m

  Scenario: Verify if the properties were correctly set when aren't passed
    When container is started with args
      | arg       | value                                                    |
      | mem_limit | 1073741824                                               |
    Then container log should match regex -Xms205m
     And container log should match regex -Xmx819m

  Scenario: Verify if the default properties are set
    When container is ready
    Then container log should contain -Ddashbuilder.runtime.allowExternal=false
     And container log should contain -Ddashbuilder.components.partition=true
     And container log should contain -Ddashbuilder.dataset.partition=true
     And container log should contain -Ddashbuilder.import.base.dir=/opt/kie/dashbuilder/imports
     And container log should contain -Ddashbuilder.removeModelFile=false
     And container log should contain -Ddashbuilder.runtime.multi=false

  Scenario: Verify if DASHBUILDER_ALLOW_EXTERNAL_FILE_REGISTER is correctly set
    When container is started with env
      | variable                                  | value   |
      | DASHBUILDER_ALLOW_EXTERNAL_FILE_REGISTER  | true    |
    Then container log should contain -Ddashbuilder.runtime.allowExternal=true

  Scenario: Verify if DASHBUILDER_COMPONENT_PARTITION and DASHBUILDER_DATASET_PARTITION are correctly set
    When container is started with env
      | variable                        | value   |
      | DASHBUILDER_COMPONENT_PARTITION | false   |
      | DASHBUILDER_DATASET_PARTITION   | false   |
    Then container log should contain -Ddashbuilder.components.partition=false
     And container log should contain -Ddashbuilder.dataset.partition=false

  Scenario: Verify if DASHBUILDER_IMPORT_FILE_LOCATION is correctly set
    When container is started with env
      | variable                         | value         |
      | DASHBUILDER_IMPORT_FILE_LOCATION | /tmp/test.zip |
    Then container log should contain -Ddashbuilder.runtime.import=/tmp/test.zip
     And container log should not contain -Ddashbuilder.import.base.dir
     And container log should not contain set using DASHBUILDER_IMPORTS_BASE_DIR env does not exist, using the default /opt/kie/dashbuilder/imports

  Scenario: Verify if the default value for dashbuilder.import.base.dir is correctly set
    When container is ready
    Then container log should contain -Ddashbuilder.import.base.dir=/opt/kie/dashbuilder/imports
     And container log should not contain set using DASHBUILDER_IMPORTS_BASE_DIR env does not exist, using the default /opt/kie/dashbuilder/imports
     And container log should not contain -Ddashbuilder.runtime.import

  Scenario: Verify if DASHBUILDER_IMPORTS_BASE_DIR is correctly set
    When container is started with env
      | variable                      | value  |
      | DASHBUILDER_IMPORTS_BASE_DIR  | /tmp   |
    Then container log should contain Dashbuilder file location import dir is /tmp
     And container log should contain -Ddashbuilder.import.base.dir=/tmp

  Scenario: Verify if DASHBUILDER_IMPORTS_BASE_DIR is correctly set to its default value when a non existent directory is set
    When container is started with env
      | variable                      | value     |
      | DASHBUILDER_IMPORTS_BASE_DIR  | /nonsense |
    Then container log should contain The directory [/nonsense] set using DASHBUILDER_IMPORTS_BASE_DIR env does not exist, using the default [/opt/kie/dashbuilder/imports]
     And container log should contain Dashbuilder file location import dir is /opt/kie/dashbuilder/imports
     And container log should contain -Ddashbuilder.import.base.dir=/opt/kie/dashbuilder/imports

  Scenario: Verify if DASHBUILDER_MODEL_UPDATE and DASHBUILDER_MODEL_FILE_REMOVAL and DASHBUILDER_RUNTIME_MULTIPLE_IMPORT are correctly set
    When container is started with env
      | variable                            | value  |
      | DASHBUILDER_MODEL_UPDATE            | false  |
      | DASHBUILDER_MODEL_FILE_REMOVAL      | true   |
      | DASHBUILDER_RUNTIME_MULTIPLE_IMPORT | true   |
    Then container log should not contain dashbuilder.runtime.import
     And container log should contain -Ddashbuilder.import.base.dir=/opt/kie/dashbuilder/imports
     And container log should contain -Ddashbuilder.model.update=false
     And container log should contain -Ddashbuilder.removeModelFile=true
     And container log should contain -Ddashbuilder.runtime.multi=true

  Scenario: Verify if DASHBUILDER_UPLOAD_SIZE is correctly set
    When container is started with env
      | variable                | value    |
      | DASHBUILDER_UPLOAD_SIZE | 10000000 |
    Then container log should contain -Ddashbuilder.runtime.upload.size=1000000

  Scenario: Verify if external component configuration is correctly set with default values
    When container is started with env
      | variable                | value  |
    Then container log should contain -Ddashbuilder.components.enable=true
     And container log should contain -Ddashbuilder.components.dir=/opt/kie/dashbuilder/components
     And container log should not contain set using DASHBUILDER_EXTERNAL_COMP_DIR env does not exist, the default /opt/kie/dashbuilder/components

  Scenario: Verify if external component configuration is correctly set with custom directory
    When container is started with env
      | variable                      | value  |
      | DASHBUILDER_EXTERNAL_COMP_DIR | /tmp   |
    Then container log should contain -Ddashbuilder.components.enable=true
     And container log should contain -Ddashbuilder.components.dir=/tmp
     And container log should contain Dashbuilder external component enabled, component dir is /tmp
     And container log should not contain set using DASHBUILDER_EXTERNAL_COMP_DIR env does not exist, the default /opt/kie/dashbuilder/components

  Scenario: Verify if external component configuration is correctly set with invalid custom directory
    When container is started with env
      | variable                      | value     |
      | DASHBUILDER_EXTERNAL_COMP_DIR | /nonsense |
    Then container log should contain -Ddashbuilder.components.enable=true
     And container log should contain -Ddashbuilder.components.dir=/opt/kie/dashbuilder/components
     And container log should contain Dashbuilder external component enabled, component dir is /opt/kie/dashbuilder/components
     And container log should contain The directory [/nonsense] set using DASHBUILDER_EXTERNAL_COMP_DIR env does not exist, the default [/opt/kie/dashbuilder/components]


  Scenario: Verify if external component configuration is correctly set with invalid custom directory
    When container is started with env
      | variable                      | value     |
      | DASHBUILDER_COMP_ENABLE       | false     |
      | DASHBUILDER_EXTERNAL_COMP_DIR | /nonsense |
    Then container log should contain -Ddashbuilder.components.enable=false
     And container log should not contain -Ddashbuilder.components.dir=/opt/kie/dashbuilder/components
     And container log should not contain Dashbuilder external component enabled, component dir is /opt/kie/dashbuilder/components
     And container log should not contain The directory [/nonsense] set using DASHBUILDER_EXTERNAL_COMP_DIR env does not exist, the default [/opt/kie/dashbuilder/components]

  Scenario: Verify if the KIE Server DataSet is correctly configured using credentials
    When container is started with env
      | variable              | value                 |
      | SCRIPT_DEBUG          | true                  |
      | KIESERVER_DATASETS    | dataset_test          |
      | dataset_test_LOCATION | http://localmoon.com  |
      | dataset_test_USER     | moon                  |
      | dataset_test_PASSWORD | sun                   |
    Then container log should contain -Ddashbuilder.kieserver.dataset.dataset_test.location=http://localmoon.com
     And container log should contain -Ddashbuilder.kieserver.dataset.dataset_test.replace_query=false
     And container log should contain -Ddashbuilder.kieserver.dataset.dataset_test.user=moon
     And container log should contain -Ddashbuilder.kieserver.dataset.dataset_test.password=sun

  Scenario: Verify if the KIE Server DataSet is correctly configured using token
    When container is started with env
      | variable              | value                 |
      | KIESERVER_DATASETS    | DataSetTest           |
      | DataSetTest_LOCATION  | http://localmoon.com  |
      | DataSetTest_TOKEN     | cool_token            |
    Then container log should contain -Ddashbuilder.kieserver.dataset.DataSetTest.location=http://localmoon.com
     And container log should contain -Ddashbuilder.kieserver.dataset.DataSetTest.replace_query=false
     And container log should contain -Ddashbuilder.kieserver.dataset.DataSetTest.token=cool_token
     And container log should not contain -Ddashbuilder.kieserver.dataset.DataSetTest.user
     And container log should not contain -Ddashbuilder.kieserver.dataset.DataSetTest.password

  Scenario: Verify if multiple KIE Server DataSet is correctly configured using credentials and token
    When container is started with env
      | variable                  | value                     |
      | SCRIPT_DEBUG              | true                      |
      | KIESERVER_DATASETS        | dataset_test,DataSetTest  |
      | dataset_test_LOCATION     | http://localmoon.com      |
      | dataset_test_USER         | moon                      |
      | dataset_test_PASSWORD     | sun                       |
      | DataSetTest_LOCATION      | http://localmoon.com      |
      | DataSetTest_REPLACE_QUERY | true                      |
      | DataSetTest_TOKEN         | cool_token                |
    Then container log should contain -Ddashbuilder.kieserver.dataset.dataset_test.location=http://localmoon.com
     And container log should contain -Ddashbuilder.kieserver.dataset.dataset_test.replace_query=false
     And container log should contain -Ddashbuilder.kieserver.dataset.dataset_test.user=moon
     And container log should contain -Ddashbuilder.kieserver.dataset.dataset_test.password=sun
     And container log should contain -Ddashbuilder.kieserver.dataset.DataSetTest.location=http://localmoon.com
     And container log should contain -Ddashbuilder.kieserver.dataset.DataSetTest.replace_query=true
     And container log should contain -Ddashbuilder.kieserver.dataset.DataSetTest.token=cool_token
     And container log should not contain -Ddashbuilder.kieserver.dataset.DataSetTest.user
     And container log should not contain -Ddashbuilder.kieserver.dataset.DataSetTest.password

  Scenario: Verify if the KIE Server serverTemplate is correctly configured using credentials
    When container is started with env
      | variable                      | value                 |
      | SCRIPT_DEBUG                  | true                  |
      | KIESERVER_SERVER_TEMPLATES    | server_template_test  |
      | server_template_test_LOCATION | http://localmoon.com  |
      | server_template_test_USER     | moon                  |
      | server_template_test_PASSWORD | sun                   |
    Then container log should contain -Ddashbuilder.kieserver.serverTemplate.server_template_test.location=http://localmoon.com
     And container log should contain -Ddashbuilder.kieserver.serverTemplate.server_template_test.replace_query=false
     And container log should contain -Ddashbuilder.kieserver.serverTemplate.server_template_test.user=moon
     And container log should contain -Ddashbuilder.kieserver.serverTemplate.server_template_test.password=sun

  Scenario: Verify if the KIE Server DataSet is correctly configured using token
    When container is started with env
      | variable                    | value                 |
      | KIESERVER_SERVER_TEMPLATES  | ServerTemplateTest    |
      | ServerTemplateTest_LOCATION | http://localmoon.com  |
      | ServerTemplateTest_TOKEN    | my_cool_token         |
    Then container log should contain -Ddashbuilder.kieserver.serverTemplate.ServerTemplateTest.location=http://localmoon.com
     And container log should contain -Ddashbuilder.kieserver.serverTemplate.ServerTemplateTest.replace_query=false
     And container log should contain -Ddashbuilder.kieserver.serverTemplate.ServerTemplateTest.token=my_cool_token
     And container log should not contain -Ddashbuilder.kieserver.serverTemplate.ServerTemplateTest.user
     And container log should not contain -Ddashbuilder.kieserver.serverTemplate.ServerTemplateTest.password

  Scenario: Verify if multiple KIE Server DataSet is correctly configured using credentials and token
    When container is started with env
      | variable                           | value                                    |
      | SCRIPT_DEBUG                       | true                                     |
      | KIESERVER_SERVER_TEMPLATES         | server_template_test,ServerTemplateTest  |
      | server_template_test_LOCATION      | http://localmoon.com                     |
      | server_template_test_REPLACE_QUERY | true                                     |
      | server_template_test_USER          | moon                                     |
      | server_template_test_PASSWORD      | sun                                      |
      | ServerTemplateTest_LOCATION        | http://localmoon.com                     |
      | ServerTemplateTest_TOKEN           | my_cool_token                            |
    Then container log should contain -Ddashbuilder.kieserver.serverTemplate.server_template_test.location=http://localmoon.com
     And container log should contain -Ddashbuilder.kieserver.serverTemplate.server_template_test.replace_query=true
     And container log should contain -Ddashbuilder.kieserver.serverTemplate.server_template_test.user=moon
     And container log should contain -Ddashbuilder.kieserver.serverTemplate.server_template_test.password=sun
     And container log should contain -Ddashbuilder.kieserver.serverTemplate.ServerTemplateTest.location=http://localmoon.com
     And container log should contain -Ddashbuilder.kieserver.serverTemplate.ServerTemplateTest.replace_query=false
     And container log should contain -Ddashbuilder.kieserver.serverTemplate.ServerTemplateTest.token=my_cool_token
     And container log should not contain -Ddashbuilder.kieserver.serverTemplate.ServerTemplateTest.user
     And container log should not contain -Ddashbuilder.kieserver.serverTemplate.ServerTemplateTest.password

  Scenario: Verify if the KIE Server serverTemplate with dash is correctly configured using credentials
    When container is started with env
      | variable                      | value                 |
      | SCRIPT_DEBUG                  | true                  |
      | KIESERVER_SERVER_TEMPLATES    | server-template-test  |
      | server_template_test_LOCATION | http://localmoon.com  |
      | server_template_test_USER     | moon                  |
      | server_template_test_PASSWORD | sun                   |
    Then container log should contain -Ddashbuilder.kieserver.serverTemplate.server-template-test.location=http://localmoon.com
     And container log should contain -Ddashbuilder.kieserver.serverTemplate.server-template-test.replace_query=false
     And container log should contain -Ddashbuilder.kieserver.serverTemplate.server-template-test.user=moon
     And container log should contain -Ddashbuilder.kieserver.serverTemplate.server-template-test.password=sun