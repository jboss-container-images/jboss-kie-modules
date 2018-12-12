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

package org.jboss.test.arquillian.ce.common;

import org.arquillian.cube.openshift.shrinkwrap.Files;
import org.arquillian.cube.openshift.shrinkwrap.Libraries;
import org.jboss.shrinkwrap.api.ShrinkWrap;
import org.jboss.shrinkwrap.api.spec.WebArchive;
import org.jboss.test.arquillian.ce.decisionserver.DecisionServerTestBase;
import org.junit.Assert;
import org.kie.server.api.marshalling.MarshallingFormat;
import org.kie.server.api.model.KieContainerResource;
import org.kie.server.api.model.KieServerInfo;
import org.kie.server.client.KieServicesClient;
import org.kie.server.client.KieServicesConfiguration;
import org.kie.server.client.KieServicesFactory;
import org.openshift.quickstarts.decisionserver.hellorules.Person;

import javax.jms.ConnectionFactory;
import javax.jms.Queue;
import javax.naming.Context;
import javax.naming.InitialContext;
import javax.xml.bind.DatatypeConverter;
import java.io.UnsupportedEncodingException;
import java.net.MalformedURLException;
import java.net.URL;
import java.security.InvalidParameterException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Properties;
import java.util.logging.Logger;
import java.util.regex.Pattern;

/**
 * @author Filippe Spolti
 * <p>
 * Place here all code/methods in common for process and decision server
 */
public abstract class KieServerTestBase {

    protected static final String FILENAME = "kie.properties";
    private KieServicesConfiguration kieServicesConfiguration;
    private HashMap<URL, KieServicesConfiguration> clients = new HashMap<>();

    public String AMQ_HOST = "tcp://kie-app-amq-tcp:61616";

    /**
     * Sort the kieContainers list in alphabetical order
     * To sort the list just add the following in the desired method:
     * Collections.sort(KieContainersList, ALPHABETICAL_ORDER);
     */
    public static final Comparator<KieContainerResource> ALPHABETICAL_ORDER = Comparator.comparing(KieContainerResource::getContainerId);

    //kie-server credentials
    protected static final String KIE_USERNAME = System.getProperty("kie.username", "kieserver");
    protected static final String KIE_PASSWORD = System.getProperty("kie.password", "Redhat@123");
    // AMQ credentials
    public static final String MQ_USERNAME = System.getProperty("mq.username", "kieserver");
    public static final String MQ_PASSWORD = System.getProperty("mq.password", "Redhat@123");

    protected static WebArchive getDeploymentInternal() throws Exception {
        WebArchive war = ShrinkWrap.create(WebArchive.class, "run-in-pod.war");
        war.setWebXML("web.xml");
        war.addClass(KieServerTestBase.class);
        war.addClass(DecisionServerTestBase.class);
        war.addPackage(Person.class.getPackage());
        war.addAsLibraries(Libraries.transitive("org.kie.server", "kie-server-client"));
        war.addAsLibraries(Libraries.transitive("org.apache.httpcomponents", "httpclient"));
        Files.PropertiesHandle handle = Files.createPropertiesHandle(FILENAME);
        handle.addProperty("kie.username", KIE_USERNAME);
        handle.addProperty("kie.password", KIE_PASSWORD);
        handle.addProperty("mq.username", MQ_USERNAME);
        handle.addProperty("mq.password", MQ_PASSWORD);
        handle.store(war);

        return war;
    }

    protected final Logger log = Logger.getLogger(KieServerTestBase.class.getName());

    protected abstract URL getRouteURL();

    protected void prepareClientInvocation() {
        // do nothing in basic
    }

    protected KieServicesConfiguration configureRestClient(URL baseURL) throws MalformedURLException {
        log.info("Received a new client build request for url " + baseURL);
        if (clients.containsKey(baseURL)) {
            log.info("Returning cached Kie client for base url: " + baseURL);
            return clients.get(baseURL);

        } else {
            log.info("Kie Service Client empty or configuration for base url " + baseURL + " not found, building a new one...");
            kieServicesConfiguration = KieServicesFactory.newRestConfiguration(new URL(baseURL,
                    "/kie-server/services/rest/server").toString(), KIE_USERNAME, KIE_PASSWORD);
            kieServicesConfiguration.setMarshallingFormat(MarshallingFormat.XSTREAM);
            clients.put(baseURL, kieServicesConfiguration);
            return kieServicesConfiguration;
        }
    }

    protected KieServicesConfiguration configureAmqClient() throws Exception {
        Properties props = new Properties();
        props.setProperty(Context.INITIAL_CONTEXT_FACTORY, "org.apache.activemq.jndi.ActiveMQInitialContextFactory");
        props.setProperty(Context.PROVIDER_URL, AMQ_HOST);
        props.setProperty(Context.SECURITY_PRINCIPAL, KIE_USERNAME);
        props.setProperty(Context.SECURITY_CREDENTIALS, KIE_PASSWORD);
        InitialContext context = new InitialContext(props);
        ConnectionFactory connectionFactory = (ConnectionFactory) context.lookup("ConnectionFactory");
        Queue requestQueue = (Queue) context.lookup("dynamicQueues/queue/KIE.SERVER.REQUEST");
        Queue responseQueue = (Queue) context.lookup("dynamicQueues/queue/KIE.SERVER.RESPONSE");
        KieServicesConfiguration kieServicesConfiguration = KieServicesFactory.newJMSConfiguration(connectionFactory, requestQueue,
                responseQueue, MQ_USERNAME, MQ_PASSWORD);
        kieServicesConfiguration.setMarshallingFormat(MarshallingFormat.XSTREAM);
        return kieServicesConfiguration;
    }

    /**
     * @param URL url - KieServer address
     * @returns the kieService client
     * @throwns MalformedURLException
     */
    protected KieServicesClient getKieRestServiceClient(URL baseURL) throws MalformedURLException {
        return KieServicesFactory.newKieServicesClient(configureRestClient(baseURL));
    }

    /**
     * Verifies the server capabilities, for:
     * decisionserver-openshift:6.4: KieServer BRM
     * processserver-openshift:6.4: KieServer BPM
     *
     * @throws MalformedURLException
     * @params URL url - kieserver address
     * String cap - capability to test
     */
    public void checkKieServerCapabilities(URL url, String cap) throws MalformedURLException {
        log.info("Running test checkKieServerCapabilities");
        // for untrusted connections
        prepareClientInvocation();

        // Getting the KieServiceClient
        KieServicesClient kieServicesClient = getKieRestServiceClient(url);
        KieServerInfo serverInfo = kieServicesClient.getServerInfo().getResult();

        // Where the result will be stored
        String serverCapabilitiesResult = "";

        // Reading Server capabilities
        for (String capability : serverInfo.getCapabilities()) {
            if (!capability.toUpperCase().equals("KIESERVER")) {
                serverCapabilitiesResult += capability; // TODO -- we used to have empty 'if' here ... ??!!?
            }
        }

        // Sometimes the getCapabilities returns "KieServer BRM" and another time "BRM KieServer"
        // We have to make sure the result will be the same always
        if ("BRM".equals(cap)) {
            Assert.assertTrue(serverCapabilitiesResult.contains("BRM"));
        } else if ("BPM".equals(cap)) {
            //for process server both BPM and BRM capabilities should be enabled
            Assert.assertTrue(serverCapabilitiesResult.contains("BPM") || serverCapabilitiesResult.contains("BRM"));
        }
    }

    /**
     * Verifies a single container
     * Verifies the KieContainer ID
     * Verifies the KieContainer Status, it should be org.kie.server.api.model.KieContainerStatus.STARTED
     *
     * @param String containerId
     * @throws Exception see getKieRestServiceClient
     */
    public void checkKieServerContainer(String containerId) throws Exception {
        log.info("Running test checkKieServerContainer");
        // for untrusted connections
        prepareClientInvocation();

        List<KieContainerResource> kieContainers = getKieRestServiceClient(getRouteURL()).listContainers().getResult().getContainers();

        log.info("Container ID: " + kieContainers.get(0).getContainerId());
        log.info("Container Status: " + kieContainers.get(0).getStatus());

        Assert.assertTrue(kieContainers.get(0).getContainerId().equals(convertKieContainerId(containerId)));
        // verify the KieContainer Status
        Assert.assertEquals(org.kie.server.api.model.KieContainerStatus.STARTED, kieContainers.get(0).getStatus());
    }

    /**
     * Convert the deployed container in a md5 hash
     *
     * @param String KieContainer in the following pattern:
     *               ContainerName=G:A:V
     *               Ex: processserver-library=org.openshift.quickstarts:processserver-library:1.4.0.Final
     * @returns the MD5 hash of the given container.
     */
    public String convertKieContainerId(String kieContainer) {
        //validate the container name received:
        final Pattern PATTERN = Pattern.compile("(^\\w*=*)(\\w:*)(\\w*:*)");
        if (!PATTERN.matcher(kieContainer).find()) {
            throw new InvalidParameterException("Please use the following format: ContainerName=G:A:V");
        }
        return md5sum(kieContainer);
    }

    /**
     * Convert the provided string into a md5 hash.
     * @param s
     * @return the MD5 hash of the given string
     */
    protected String md5sum(String s) {
        try {
            MessageDigest md5 = MessageDigest.getInstance("MD5");
            byte[] digest = md5.digest(s.getBytes("UTF-8"));
            return DatatypeConverter.printHexBinary(digest).toLowerCase();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("Failed to generate the MD5 hash of [" + s + "]: " + e.getMessage());
        } catch (UnsupportedEncodingException e) {
            throw new RuntimeException("Failed to generate the MD5 hash of [" + s + "]: " + e.getMessage());
        }
    }
}
