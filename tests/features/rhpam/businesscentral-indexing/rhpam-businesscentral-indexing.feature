@rhpam-7/rhpam70-businesscentral-indexing-openshift
Feature: RHPAM Business Central Indexing configuration tests

  @wip
  Scenario: Test Container Health
    When container is ready
    Then check that page is served
      | property             | value               |
      | port                 | 9200                |
      | path                 | /_cluster/health    |
      | expected_status_code | 200                 |
      | expected_phrase      | green               |

  @wip
  Scenario: Test default heap memory
    When container is ready
    Then container log should contain -Xms1024m, -Xmx1024m

  @wip
  Scenario: Check if the memory is correctly configure with container limits
    When container is started with args
      | arg       | value                           |
      | mem_limit | 1073741824                      |
      | env_json  | {"JAVA_INITIAL_MEM_RATIO": 100} |
    Then container log should contain -Xms512m, -Xmx512m

  @wip
  Scenario: Check if the minimum master nodes variable is correctly set
    When container is started with env
      | variable                | value    |
      | ES_MINIMUM_MASTER_NODES | 2        |
    Then container log should contain not enough master nodes discovered during pinging
     And container log should contain but needed [2]), pinging again

  @wip
  Scenario: Check cluster name is correctly set
    When container is started with env
      | variable        | value          |
      | ES_CLUSTER_NAME | my-kie-cluster |
    Then check that page is served
      | property             | value                              |
      | port                 | 9200                               |
      | path                 | /_cluster/health                   |
      | expected_status_code | 200                                |
      | expected_phrase      | "cluster_name":"my-kie-cluster"    |

  @wip
  Scenario: Check if the node name correctly set
    When container is started with env
      | variable       | value    |
      | ES_NODE_NAME   | NodeA    |
    Then container log should contain node name [NodeA]

  @wip
  Scenario: Check if bind address is correctly set
    When container is started with env
      | variable            | value       |
      | ES_HTTP_HOST        | 127.0.0.1   |
      | ES_TRANSPORT_HOST   | 127.0.0.1   |
    Then container log should contain publish_address {127.0.0.1:9200}, bound_addresses {127.0.0.1:9200}
     And container log should contain publish_address {127.0.0.1:9300}, bound_addresses {127.0.0.1:9300}

  @wip
  Scenario: Check if ports is correctly set
    When container is started with env
      | variable              | value       |
      | ES_HTTP_HOST          | 127.0.0.1   |
      | ES_TRANSPORT_HOST     | 127.0.0.1   |
      | ES_HTTP_PORT          | 5000        |
      | ES_TRANSPORT_TCP_PORT | 6000        |
    Then container log should contain publish_address {127.0.0.1:5000}, bound_addresses {127.0.0.1:5000}
     And container log should contain publish_address {127.0.0.1:6000}, bound_addresses {127.0.0.1:6000}
