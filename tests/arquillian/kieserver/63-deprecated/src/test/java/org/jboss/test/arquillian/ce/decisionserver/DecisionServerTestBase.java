/*
 * JBoss, Home of Professional Open Source
 * Copyright 2015 Red Hat Inc. and/or its affiliates and other
 * contributors as indicated by the @author tags. All rights reserved.
 * See the copyright.txt in the distribution for a full listing of
 * individual contributors.
 *
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org.
 */

package org.jboss.test.arquillian.ce.decisionserver;

import java.io.IOException;
import java.io.StringReader;
import java.net.MalformedURLException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Properties;
import java.util.Set;
import java.util.logging.Logger;

import javax.jms.ConnectionFactory;
import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBException;
import javax.xml.bind.Unmarshaller;

import org.jboss.arquillian.ce.api.ConfigurationHandle;
import org.jboss.arquillian.ce.httpclient.HttpClient;
import org.jboss.arquillian.ce.httpclient.HttpClientBuilder;
import org.jboss.arquillian.ce.httpclient.HttpRequest;
import org.jboss.arquillian.ce.httpclient.HttpResponse;
import org.jboss.arquillian.test.api.ArquillianResource;
import org.jboss.test.arquillian.ce.common.KieServerTestBase;
import org.junit.Assert;
import org.kie.api.command.BatchExecutionCommand;
import org.kie.api.command.Command;
import org.kie.api.runtime.ExecutionResults;
import org.kie.api.runtime.rule.QueryResults;
import org.kie.api.runtime.rule.QueryResultsRow;
import org.kie.internal.command.CommandFactory;
import org.kie.internal.runtime.helper.BatchExecutionHelper;
import org.kie.server.api.marshalling.Marshaller;
import org.kie.server.api.marshalling.MarshallerFactory;
import org.kie.server.api.marshalling.MarshallingFormat;
import org.kie.server.api.model.KieContainerResource;
import org.kie.server.api.model.KieContainerResourceList;
import org.kie.server.api.model.KieServerInfo;
import org.kie.server.api.model.ServiceResponse;
import org.kie.server.client.KieServicesClient;
import org.kie.server.client.KieServicesConfiguration;
import org.kie.server.client.KieServicesFactory;
import org.kie.server.client.RuleServicesClient;
import org.openshift.quickstarts.decisionserver.hellorules.Greeting;
import org.openshift.quickstarts.decisionserver.hellorules.Person;

import io.fabric8.utils.Base64Encoder;

/**
 * @author Filippe Spolti
 * @author Ales justin
 */
public abstract class DecisionServerTestBase extends KieServerTestBase {
    protected final Logger log = Logger.getLogger(getClass().getName());

    public Person person = new Person();

    @ArquillianResource
    protected ConfigurationHandle configuration;

    /*
    * Returns the JMS kieService client
    * TODO move to KieServerTestBase
    */
    public KieServicesClient getKieJmsServiceClient() throws NamingException {
        Properties props = new Properties();
        props.setProperty(Context.INITIAL_CONTEXT_FACTORY, "org.apache.activemq.jndi.ActiveMQInitialContextFactory");
        props.setProperty(Context.PROVIDER_URL, AMQ_HOST);
        props.setProperty(Context.SECURITY_PRINCIPAL, KIE_USERNAME);
        props.setProperty(Context.SECURITY_CREDENTIALS, KIE_PASSWORD);
        InitialContext context = new InitialContext(props);
        ConnectionFactory connectionFactory = (ConnectionFactory) context.lookup("ConnectionFactory");
        javax.jms.Queue requestQueue = (javax.jms.Queue) context.lookup("dynamicQueues/queue/KIE.SERVER.REQUEST");
        javax.jms.Queue responseQueue = (javax.jms.Queue) context.lookup("dynamicQueues/queue/KIE.SERVER.RESPONSE");
        KieServicesConfiguration config = KieServicesFactory.newJMSConfiguration(connectionFactory, requestQueue, responseQueue, MQ_USERNAME, MQ_PASSWORD);
        config.setMarshallingFormat(MarshallingFormat.XSTREAM);
        return KieServicesFactory.newKieServicesClient(config);
    }

    /*
    * Return the RuleServicesClient
    */
    public RuleServicesClient getRuleServicesClient(KieServicesClient client) {
        return client.getServicesClient(RuleServicesClient.class);
    }

    /*
     * Return the classes used in the MarshallerFactory
     */
    public Set<Class<?>> getClasses() {
        Set<Class<?>> classes = new HashSet<>();
        classes.add(Person.class);
        classes.add(Greeting.class);
        return classes;
    }

    /*
     * Return the batch command used to fire rules
     */
    public BatchExecutionCommand batchCommand() {
        person.setName("Filippe Spolti");
        List<Command<?>> commands = new ArrayList<>();
        commands.add((Command<?>) CommandFactory.newInsert(person));
        commands.add((Command<?>) CommandFactory.newFireAllRules());
        commands.add((Command<?>) CommandFactory.newQuery("greetings", "get greeting"));
        return CommandFactory.newBatchExecution(commands, "HelloRulesSession");
    }

    /*
    * Verifies the KieContainer ID, it should be 41895328c0d0a1747e2b24d53cbbfeb2 for decisionserver-hellorules
    *                                        and 5fe16e3ab6fc8ae7fbf9fd71b8eb57f1 for AnotherContainer
    * Verifies the KieContainer Status, it should be org.kie.server.api.model.KieContainerStatus.STARTED
    */
    public void checkDecisionServerContainer() throws MalformedURLException {
        log.info("Running test checkDecisionServerContainer");

        // for untrusted connections
        prepareClientInvocation();

        for (KieContainerResource container : getKieRestServiceClient(getRouteURL()).listContainers().getResult().getContainers()) {
            String containerAliasToID = md5sum(container.getResolvedReleaseId().getArtifactId() + "=" + container.getReleaseId());
            //Make sure the second container name is AnotherContainer
            if (!containerAliasToID.equals(container.getContainerId())) {
                containerAliasToID = md5sum("AnotherContainer=" + container.getReleaseId());
            }
            Assert.assertTrue(container.getContainerId().equals(containerAliasToID));
            Assert.assertEquals(org.kie.server.api.model.KieContainerStatus.STARTED, container.getStatus());
        }
    }

    /*
    * Test the rule deployed on Openshift, the template used to register the HelloRules container with the Kie jar:
    * https://github.com/jboss-openshift/openshift-quickstarts/tree/master/decisionserver
    */
    public void checkFireAllRules() throws MalformedURLException {
        log.info("Running test checkFireAllRules");
        // for untrusted connections
        prepareClientInvocation();

        KieServicesClient client = getKieRestServiceClient(getRouteURL());

        ServiceResponse<ExecutionResults> response = getRuleServicesClient(client).executeCommandsWithResults("decisionserver-hellorules", batchCommand());

        // response cannot be null
        Assert.assertNotNull(response);

        QueryResults queryResults = (QueryResults) response.getResult().getValue("greetings");
        Greeting greeting = new Greeting();
        for (QueryResultsRow queryResult : queryResults) {
            greeting = (Greeting) queryResult.get("greeting");
            System.out.println("Result: " + greeting.getSalutation());
        }

        Assert.assertEquals("Hello " + person.getName() + "!", greeting.getSalutation());
    }

    /*
    * Test the rule deployed on Openshift using AMQ client, the template used to register the HelloRules container with the Kie jar:
    * https://github.com/jboss-openshift/openshift-quickstarts/tree/master/decisionserver
    */
    public void checkFireAllRulesAMQ() throws NamingException {
        log.info("Running test checkFireAllRulesAMQ");
        log.info("Trying to connect to AMQ HOST: " + AMQ_HOST);

        KieServicesClient client = getKieJmsServiceClient();

        ServiceResponse<ExecutionResults> response = getRuleServicesClient(client).executeCommandsWithResults("decisionserver-hellorules", batchCommand());

        // results cannot be null
        Assert.assertNotNull(response);

        QueryResults queryResults = (QueryResults) response.getResult().getValue("greetings");
        Greeting greeting = new Greeting();
        for (QueryResultsRow queryResult : queryResults) {
            greeting = (Greeting) queryResult.get("greeting");
            System.out.println("Result AMQ: " + greeting.getSalutation());
        }

        Assert.assertEquals("Hello " + person.getName() + "!", greeting.getSalutation());
    }

    /*
    * Verifies the server capabilities using AMQ client, for decisionserver-openshift:6.2 it
    * should be KieServer BRM
    */
    public void checkDecisionServerCapabilitiesAMQ() throws NamingException {
        log.info("Running test checkDecisionServerCapabilitiesAMQ");
        log.info("Trying to connect to AMQ HOST: " + AMQ_HOST);
        // Where the result will be stored
        String serverCapabilitiesResult = "";

        // Getting the KieServiceClient JMS
        KieServicesClient kieServicesClient = getKieJmsServiceClient();
        KieServerInfo serverInfo = kieServicesClient.getServerInfo().getResult();

        // Reading Server capabilities
        for (String capability : serverInfo.getCapabilities()) {
            serverCapabilitiesResult += (capability);
        }

        // Sometimes the getCapabilities returns "KieServer BRM" and another time "BRM KieServer"
        // We have to make sure the result will be the same always
        Assert.assertTrue(serverCapabilitiesResult.equals("KieServerBRM") || serverCapabilitiesResult.equals("BRMKieServer"));
    }


    //Multiple Container Tests

    /*
    * Verifies the KieContainer ID, it should be decisionserver-hellorules
    * Verifies the KieContainer Status, it should be org.kie.server.api.model.KieContainerStatus.STARTED
    */
    public void checkDecisionServerContainerAMQ() throws NamingException {
        log.info("Running test checkDecisionServerContainerAMQ");
        log.info("Trying to connect to AMQ HOST: " + AMQ_HOST);
        for (KieContainerResource container : getKieJmsServiceClient().listContainers().getResult().getContainers()) {
            String containerAliasToID = md5sum(container.getResolvedReleaseId().getArtifactId() + "=" + container.getReleaseId());
            //Make sure the second container name is AnotherContainer
            if (!containerAliasToID.equals(container.getContainerId())) {
                containerAliasToID = md5sum("AnotherContainer=" + container.getReleaseId());
            }
            Assert.assertTrue(container.getContainerId().equals(containerAliasToID));
            Assert.assertEquals(org.kie.server.api.model.KieContainerStatus.STARTED, container.getStatus());
        }
    }

    /*
    * Tests a decision server with 2 containers:
    * Verifies the KieContainer ID, it should be AnotherContainer
    * Verifies the KieContainer Status, it should be org.kie.server.api.model.KieContainerStatus.STARTED
    */
    public void checkSecondDecisionServerContainer() throws MalformedURLException {
        log.info("Running test checkSecondDecisionServerContainer");
        // for untrusted connections
        prepareClientInvocation();
        List<KieContainerResource> kieContainers = getKieRestServiceClient(getRouteURL()).listContainers().getResult().getContainers();

        // Sorting kieContainerList
        Collections.sort(kieContainers, ALPHABETICAL_ORDER);

        //kieContainers size should be 2
        Assert.assertEquals(2, kieContainers.size());

        //Convert the KIE_CONTAINER_DEPLOYMENT into md5 hash
        String containerAliasToID = convertKieContainerId("AnotherContainer=org.openshift.quickstarts:decisionserver-hellorules:1.3.0.Final");

        // verify the KieContainer Name
        Assert.assertEquals(containerAliasToID, kieContainers.get(1).getContainerId());
        // verify the KieContainer Status
        Assert.assertEquals(org.kie.server.api.model.KieContainerStatus.STARTED, kieContainers.get(1).getStatus());
    }

    /*
    * Test the rule deployed on Openshift, the template used to register the HelloRules container with the Kie jar:
    * https://github.com/jboss-openshift/openshift-quickstarts/tree/master/decisionserver
    */
    public void checkFireAllRulesInSecondContainer() throws MalformedURLException {
        log.info("Running test checkFireAllRulesInSecondContainer");
        // for untrusted connections
        prepareClientInvocation();
        KieServicesClient client = getKieRestServiceClient(getRouteURL());

        ServiceResponse<ExecutionResults> response = getRuleServicesClient(client).executeCommandsWithResults("AnotherContainer", batchCommand());

        Assert.assertTrue(response.getResult() != null && response.getResult().getIdentifiers().size() > 0);

        // results cannot be null
        Assert.assertNotNull(response);

        QueryResults queryResults = (QueryResults) response.getResult().getValue("greetings");
        Greeting greeting = new Greeting();
        for (QueryResultsRow queryResult : queryResults) {
            greeting = (Greeting) queryResult.get("greeting");
            System.out.println("Result: " + greeting.getSalutation());
        }

        Assert.assertEquals("Hello " + person.getName() + "!", greeting.getSalutation());
    }

    /*
    * Verifies the Second KieContainer ID using AMQ client, it should be AnotherContainer
    * Verifies the KieContainer Status, it should be org.kie.server.api.model.KieContainerStatus.STARTED
    */
    public void checkDecisionServerSecondContainerAMQ() throws NamingException {
        log.info("Running test checkDecisionServerSecondContainerAMQ");
        List<KieContainerResource> kieContainers = getKieJmsServiceClient().listContainers().getResult().getContainers();

        // Sorting kieContainerList
        Collections.sort(kieContainers, ALPHABETICAL_ORDER);

        //kieContainers size should be 2
        Assert.assertEquals(2, kieContainers.size());

        // verify the KieContainer Name
        Assert.assertEquals(convertKieContainerId("AnotherContainer=org.openshift.quickstarts:decisionserver-hellorules:1.3.0.Final"), kieContainers.get(1).getContainerId());
        // verify the KieContainer Status
        Assert.assertEquals(org.kie.server.api.model.KieContainerStatus.STARTED, kieContainers.get(1).getStatus());
    }

    /*
    * Test the rule deployed on Openshift using AMQ client, this test case register a new template called AnotherContainer with the Kie jar:
    * https://github.com/jboss-openshift/openshift-quickstarts/tree/master/decisionserver
    */
    public void checkFireAllRulesInSecondContainerAMQ() throws NamingException {
        log.info("Running test checkFireAllRulesInSecondContainerAMQ");
        log.info("Trying to connect to AMQ HOST: " + AMQ_HOST);

        KieServicesClient client = getKieJmsServiceClient();

        ServiceResponse<ExecutionResults> response = getRuleServicesClient(client).executeCommandsWithResults("AnotherContainer", batchCommand());

        Assert.assertTrue(response.getResult() != null && response.getResult().getIdentifiers().size() > 0);

        // results cannot be null
        Assert.assertNotNull(response);

        QueryResults queryResults = (QueryResults) response.getResult().getValue("greetings");
        Greeting greeting = new Greeting();
        for (QueryResultsRow queryResult : queryResults) {
            greeting = (Greeting) queryResult.get("greeting");
            System.out.println("Result AMQ: " + greeting.getSalutation());
        }

        Assert.assertEquals("Hello " + person.getName() + "!", greeting.getSalutation());
    }

    /*
     * Returns httpClient client
     * @throws Exception, inherited from org.jboss.arquillian.ce.httpclient.untrustedConnectionClient()
     */
    private HttpClient getClient() throws Exception {
        return HttpClientBuilder.untrustedConnectionClient();
    }

    /*
    * Returns httpClient client Authorization Base64 encoded
    */
    private String authEncoding() {
        return Base64Encoder.encode(KIE_USERNAME + ":" + KIE_PASSWORD);
    }

    /*
     *Return the formatted xml to perform the fire-all-rules using httpClient
     */
    private String streamXML() {
        return BatchExecutionHelper.newXStreamMarshaller().toXML(batchCommand());
    }

    /*
    * Return the HttpPost response for fire-all-rules using httpClient
    * @throws Exception - see getClient()
    */
    private HttpResponse responseFireAllRules(String host, String containerId) throws Exception {

        //request
        HttpRequest request = HttpClientBuilder.doPOST(host + "/kie-server/services/rest/server/containers/instances/" + containerId);
        //setting headers
        request.setHeader("accept", "application/xml");
        request.setHeader("X-KIE-ContentType", "XSTREAM");
        request.setHeader("Content-Type", "application/xml");
        request.setHeader("X-KIE-ClassType", "org.drools.core.command.runtime.BatchExecutionCommandImpl");

        //setting authorization
        request.setHeader("Authorization", "Basic " + authEncoding());

        //Set the request post body
        request.setEntity(streamXML());

        //performing request
        HttpClient client = getClient();
        return client.execute(request);
    }

    /*
    * Return the HttpGet response for generic requests using httpClient
    */
    private HttpResponse genericResponse(String host, String uri) {
        //request
        HttpRequest request = HttpClientBuilder.doGET(host + uri);
        try {
            //setting header
            request.setHeader("accept", "application/xml");
            //setting authorization
            request.setHeader("Authorization", "Basic " + authEncoding());
            return getClient().execute(request);
        } catch (Throwable e) {
            throw new RuntimeException(String.format("Error executing request: %s", request), e);
        }
    }

    /* Verifies the server capabilities using httpClient, for decisionserver-openshift:6.2 it
    * should be KieServer BRM
    */
    public void checkDecisionServerCapabilitiesHttpClient() {

        String HOST = "https://" + System.getenv("SECURE_KIE_APP_SERVICE_HOST") + ":" + System.getenv("SECURE_KIE_APP_SERVICE_PORT");
        String URI = "/kie-server/services/rest/server";

        //performing request
        HttpResponse response = genericResponse(HOST, URI);

        //response code should be 200
        Assert.assertEquals(200, response.getResponseCode());

        // retrieving output response
        String output = null;
        try {
            output = response.getResponseBodyAsString();

            //converting response in a object (org.kie.server.api.model.ServiceResponse)
            JAXBContext jaxbContent = JAXBContext.newInstance(ServiceResponse.class);
            Unmarshaller unmarshaller = jaxbContent.createUnmarshaller();

            ServiceResponse<?> serviceResponse = (ServiceResponse<?>) unmarshaller.unmarshal(new StringReader(output));
            KieServerInfo serverInfo = (KieServerInfo) serviceResponse.getResult();

            // Reading Server capabilities
            String serverCapabilitiesResult = "";
            for (String capability : serverInfo.getCapabilities()) {
                serverCapabilitiesResult += (capability);
            }

            Assert.assertTrue(serverCapabilitiesResult.equals("KieServerBRM") || serverCapabilitiesResult.equals("BRMKieServer"));

        } catch (IOException e) {
            e.printStackTrace();
        } catch (JAXBException e) {
            e.printStackTrace();
        }
    }

    /*
    * Verifies the KieContainer ID
    * Verifies the KieContainer Status, it should be org.kie.server.api.model.KieContainerStatus.STARTED
    * test using httpClient
    */
    public void checkDecisionServerSecureMultiContainerHttpClient() {

        String HOST = "https://" + System.getenv("SECURE_KIE_APP_SERVICE_HOST") + ":" + System.getenv("SECURE_KIE_APP_SERVICE_PORT");
        String URI = "/kie-server/services/rest/server/containers";

        //Retrieving response
        HttpResponse response = genericResponse(HOST, URI);

        //response code should be 200
        Assert.assertEquals(200, response.getResponseCode());

        // retrieving output response
        String output = null;
        try {
            output = response.getResponseBodyAsString();


            //converting response in a object (org.kie.server.api.model.ServiceResponse)
            JAXBContext jaxbContent = JAXBContext.newInstance(ServiceResponse.class);
            Unmarshaller unmarshaller = jaxbContent.createUnmarshaller();

            ServiceResponse<?> serviceResponse = (ServiceResponse<?>) unmarshaller.unmarshal(new StringReader(output));
            KieContainerResourceList kieContainers = (KieContainerResourceList) serviceResponse.getResult();

            //kieContainers's should be 2
            Assert.assertEquals(2, kieContainers.getContainers().size());
            for (KieContainerResource container : kieContainers.getContainers()) {
                String containerAliasToID = md5sum(container.getResolvedReleaseId().getArtifactId() + "=" + container.getReleaseId());
                //Make sure the second container name is AnotherContainer
                if (!containerAliasToID.equals(container.getContainerId())) {
                    containerAliasToID = md5sum("AnotherContainer=" + container.getReleaseId());
                }
                Assert.assertEquals(container.getContainerId(), containerAliasToID);
                Assert.assertEquals(org.kie.server.api.model.KieContainerStatus.STARTED, container.getStatus());
            }
        } catch (IOException e) {
            e.printStackTrace();
        } catch (JAXBException e) {
            e.printStackTrace();
        }
    }

    /*
    * Test the rule deployed on Openshift using httpClient, the template used register the decisionserver-hellorules with the Kie jar:
    * https://github.com/jboss-openshift/openshift-quickstarts/tree/master/decisionserver
    * @throwns Exception, see responseFireAllRules
    */
    public void checkFireAllRulesSecureHttpClient() throws Exception {

        String HOST = "https://" + System.getenv("SECURE_KIE_APP_SERVICE_HOST") + ":" + System.getenv("SECURE_KIE_APP_SERVICE_PORT");

        HttpResponse response = responseFireAllRules(HOST, "decisionserver-hellorules");

        //response code should be 200
        Assert.assertEquals(200, response.getResponseCode());

        // retrieving output response
        String output = response.getResponseBodyAsString();
        Assert.assertTrue(output != null && output.length() > 0);

        Marshaller marshaller = MarshallerFactory.getMarshaller(getClasses(), MarshallingFormat.XSTREAM, Person.class.getClassLoader());
        ServiceResponse<ExecutionResults> serviceResponse = marshaller.unmarshall(output, null);

        Assert.assertTrue(serviceResponse.getType() == ServiceResponse.ResponseType.SUCCESS);

        QueryResults queryResults = (QueryResults) serviceResponse.getResult().getValue("greetings");
        Greeting greeting = new Greeting();
        for (QueryResultsRow queryResult : queryResults) {
            greeting = (Greeting) queryResult.get("greeting");
            System.out.println("Result: " + greeting.getSalutation());
        }

        Assert.assertEquals("Hello " + person.getName() + "!", greeting.getSalutation());
    }

    /*
    * Test the rule deployed on Openshift using httpClient and multicontainer feature, the template used register the
    * AnotherContainer with the Kie jar:
    * https://github.com/jboss-openshift/openshift-quickstarts/tree/master/decisionserver
    * @throwns Exception, see responseFireAllRules
    */
    public void checkFireAllRulesSecureSecondContainerHttpClient() throws Exception {

        String HOST = "https://" + System.getenv("SECURE_KIE_APP_SERVICE_HOST") + ":" + System.getenv("SECURE_KIE_APP_SERVICE_PORT");

        //The value used here should be the same on the template definition
        HttpResponse response = responseFireAllRules(HOST, convertKieContainerId("AnotherContainer=org.openshift.quickstarts:decisionserver-hellorules:1.3.0.Final"));

        //response code should be 200
        Assert.assertEquals(200, response.getResponseCode());

        // retrieving output response
        String output = response.getResponseBodyAsString();
        Assert.assertTrue(output != null && output.length() > 0);

        Marshaller marshaller = MarshallerFactory.getMarshaller(getClasses(), MarshallingFormat.XSTREAM, Person.class.getClassLoader());
        ServiceResponse<ExecutionResults> serviceResponse = marshaller.unmarshall(output, null);

        Assert.assertTrue(serviceResponse.getType() == ServiceResponse.ResponseType.SUCCESS);
        QueryResults queryResults = (QueryResults) serviceResponse.getResult().getValue("greetings");

        Greeting greeting = new Greeting();
        for (QueryResultsRow queryResult : queryResults) {
            greeting = (Greeting) queryResult.get("greeting");
            System.out.println("Result: " + greeting.getSalutation());
        }

        Assert.assertEquals("Hello " + person.getName() + "!", greeting.getSalutation());
    }
}