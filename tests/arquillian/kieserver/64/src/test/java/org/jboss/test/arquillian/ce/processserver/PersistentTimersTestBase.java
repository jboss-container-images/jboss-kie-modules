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

package org.jboss.test.arquillian.ce.processserver;

import org.arquillian.cube.openshift.api.OpenShiftHandle;
import org.jboss.arquillian.container.test.api.RunAsClient;
import org.jboss.arquillian.junit.InSequence;
import org.jboss.arquillian.test.api.ArquillianResource;
import org.jboss.test.arquillian.ce.common.KieServerTestBase;
import org.junit.Assert;
import org.junit.Test;
import org.kie.server.api.model.instance.VariableInstance;
import org.kie.server.client.ProcessServicesClient;
import org.kie.server.client.QueryServicesClient;
import org.kie.server.client.UserTaskServicesClient;
import org.openshift.quickstarts.processserver.timerprocess.Inputs;

import java.io.UnsupportedEncodingException;
import java.net.MalformedURLException;
import java.net.URL;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.Map;
import java.util.logging.Logger;
import java.util.stream.Collectors;

/**
 * @author fspolti
 */
public class PersistentTimersTestBase extends KieServerTestBase {

    private final String TIMER_PROCESS_NAME = "timerprocess.QuartzTimerProcess";
    private final Logger log = Logger.getLogger(PersistentTimersTestBase.class.getName());

    @ArquillianResource
    private OpenShiftHandle adapter;

    @Override
    protected URL getRouteURL() {
        return null;
    }

    /**
     * Test if the containerID is correctly
     *
     * @throws Exception for any issue
     */
    @Test
    @RunAsClient
    @InSequence(1)
    public void checkContainerId() throws Exception {
        checkKieServerContainer("timerProcess=org.openshift.quickstarts:processserver-timerprocess:1.4.0.Final");
    }

    /**
     * Test the bpm process normal flow
     *
     * @throws MalformedURLException        if the provided url is not valid
     * @throws UnsupportedEncodingException if the encoding used is unsupported
     * @throws NoSuchAlgorithmException     if the algorithm used is not found
     */
    @Test
    @RunAsClient
    @InSequence(2)
    public void testTimerProcessNormalWorkFlow() throws UnsupportedEncodingException, NoSuchAlgorithmException, MalformedURLException {
        // Start Process - PLUS operation
        long processIdPlus = startProcess(containerId(), TIMER_PROCESS_NAME);
        log.info("PLUS operation process ID: " + processIdPlus);
        Assert.assertNotNull(processIdPlus);
        log.info("Completing task ID: " + processIdPlus);
        completeTask(containerId(), processIdPlus, 10, 20, Operation.PLUS);
        int plusResult = Integer.parseInt(getVariable(processIdPlus).toString());
        log.info("Result PLUS operation: [ 10 + 20 = " + plusResult + "]");
        Assert.assertEquals(30, plusResult);

        // Start a process - MINUS operation
        long processIdMinus = startProcess(containerId(), TIMER_PROCESS_NAME);
        log.info("MINUS operation process ID: " + processIdMinus);
        Assert.assertNotNull(processIdMinus);
        log.info("Completing task ID: " + processIdMinus);
        completeTask(containerId(), processIdMinus, 490, 332, Operation.MINUS);
        int minusResult = Integer.parseInt(getVariable(processIdMinus).toString());
        log.info("Result MINUS operation: [ 490 - 332 = " + minusResult + "]");
        Assert.assertEquals(158, minusResult);

        // Start Process - TIMES operation
        long processIdTimes = startProcess(containerId(), TIMER_PROCESS_NAME);
        log.info("TIMES operation process ID: " + processIdTimes);
        Assert.assertNotNull(processIdTimes);
        log.info("Completing task ID: " + processIdTimes);
        completeTask(containerId(), processIdTimes, 44, 671, Operation.TIMES);
        int timesResult = Integer.parseInt(getVariable(processIdTimes).toString());
        log.info("Result TIMES operation: [ 44 * 671 = " + timesResult + "]");
        Assert.assertEquals(29524, timesResult);

        //Start Process - DIVIDE operation
        long processIdDivide = startProcess(containerId(), TIMER_PROCESS_NAME);
        log.info("DIVIDE operation process ID: " + processIdDivide);
        Assert.assertNotNull(processIdDivide);
        log.info("Completing task ID: " + processIdDivide);
        completeTask(containerId(), processIdDivide, 1000, 50, Operation.DIVIDE);
        int divideResult = Integer.parseInt(getVariable(processIdDivide).toString());
        log.info("Result DIVIDE operation: [ 1000 / 50 = " + divideResult + "]");
        Assert.assertEquals(20, divideResult);
    }

    /**
     * Start 2 processes
     *
     * @throws MalformedURLException        if the provided url is not valid
     */
    @Test
    @RunAsClient
    @InSequence(3)
    public void startProcesses() throws MalformedURLException {
        startProcess(containerId(), TIMER_PROCESS_NAME);
        log.info("PROCESS_ID_1 id: " + 5);

        startProcess(containerId(), TIMER_PROCESS_NAME);
        log.info("PROCESS_ID_2 id: " + 6);
    }

    /**
     * Restart the pods
     *
     * @throws Exception for any issue
     */
    @Test
    @RunAsClient
    @InSequence(4)
    public void restartKieServer() throws Exception {
        log.info("Scaling the pods down...");
        adapter.scaleDeployment("kie-app", 0);
        if (this.getClass().toString().endsWith("ProcessServerPersistentTimersPostgreSqlTest")) {
            adapter.scaleDeployment("kie-app-postgresql", 0);
        } else {
            adapter.scaleDeployment("kie-app-mysql", 0);
        }
        log.info("... Done");

        log.info("Scaling the pods up...");
        if (this.getClass().toString().endsWith("ProcessServerPersistentTimersPostgreSqlTest")) {
            adapter.scaleDeployment("kie-app-postgresql", 1);
        } else {
            adapter.scaleDeployment("kie-app-mysql", 1);
        }
        adapter.scaleDeployment("kie-app", 1);
        log.info("... Done");
    }

    /**
     * Test if the timers still active after a pod restart then complete the human task
     *
     * @throws MalformedURLException        if the provided url is not valid
     * @throws UnsupportedEncodingException if the encoding used is unsupported
     * @throws NoSuchAlgorithmException     if the algorithm used is not found
     */
    @Test
    @RunAsClient
    @InSequence(5)
    public void completeProcessAfterRestart() throws UnsupportedEncodingException, NoSuchAlgorithmException, MalformedURLException {
        log.info("Completing task ID: " + 5);
        completeTask(containerId(), 5, 40, 584, Operation.PLUS);
        int process_id_1_result = Integer.parseInt(getVariable(5).toString());
        log.info("RESULT AFTER RESTART: " + process_id_1_result);
        Assert.assertEquals(624, process_id_1_result);

        log.info("Completing task ID: " + 6);
        completeTask(containerId(), 6, 584, 40, Operation.MINUS);
        int process_id_2_result = Integer.parseInt(getVariable(6).toString());
        log.info("RESULT AFTER RESTART: " + process_id_2_result);
        Assert.assertEquals(544, process_id_2_result);
    }

    /**
     * Start a process
     *
     * @param containerID String
     * @param processName String
     * @return long processID
     * @throws MalformedURLException if the provided url is not valid
     */
    private long startProcess(String containerID, String processName) throws MalformedURLException {
        ProcessServicesClient processServicesClient = getKieServerProcessClient(ProcessServicesClient.class);
        return processServicesClient.startProcess(containerID, processName);
    }

    /**
     * Complete a Human Task
     *
     * @param containerId String
     * @param processId   long
     * @param number1     int
     * @param number2     int
     * @param operator    Enum Operation
     * @throws MalformedURLException        if the provided url is not valid
     * @throws UnsupportedEncodingException if the encoding used is unsupported
     * @throws NoSuchAlgorithmException     if the algorithm used is not found
     */
    private void completeTask(String containerId, long processId, Integer number1, Integer number2, Enum operator) throws MalformedURLException, UnsupportedEncodingException, NoSuchAlgorithmException {
        UserTaskServicesClient userTaskServicesClient = getKieServerProcessClient(UserTaskServicesClient.class);
        userTaskServicesClient.startTask(containerId, processId, KIE_USERNAME);
        userTaskServicesClient.completeTask(containerId, processId, KIE_USERNAME, parameters(number1, number2, operator));
    }

    /**
     * Search for a process variable
     *
     * @param processId long
     * @return Object result
     * @throws MalformedURLException        if the provided url is not valid
     */
    private Object getVariable(long processId) throws MalformedURLException {
        QueryServicesClient queryClient = getKieServerProcessClient(QueryServicesClient.class);
        return queryClient.findVariableHistory(processId, "result", 0, 1)
                .stream()
                .map(VariableInstance::getValue)
                .collect(Collectors.joining());
    }

    /**
     * In the KieServer 64 the containers are converted to a MD5 hash in the following patter: CONTAINER_ID=G:A:V
     *
     * @return convertKieContainerId
     */
    private String containerId() {
        return convertKieContainerId("timerProcess=org.openshift.quickstarts:processserver-timerprocess:1.4.0.Final");
    }

    /**
     * Returns the needed parameters needed by the timerprocess.QuartzTimerProcess
     *
     * @param number1  Integer
     * @param number2  Integer
     * @param operator Enum Operation
     * @return Map parameters
     */
    private Map<String, Object> parameters(Integer number1, Integer number2, Enum operator) {
        Inputs input = new Inputs();
        input.setNumber1(number1);
        input.setNumber2(number2);
        input.setOperator(String.valueOf(Operation.valueOf(operator.name()).operator));
        Map<String, Object> parameters = new HashMap<>();
        parameters.put("input", input);
        return parameters;
    }

    /**
     * Returns the client based on the given class passed to this method
     *
     * @param clazz The needed Clients for this test are:
     *              ProcessServicesClient.class
     *              UserTaskServicesClient.class
     *              QueryServicesClient.class
     * @throws MalformedURLException if the provided url is not valid
     */
    private <T> T getKieServerProcessClient(Class<T> clazz) throws MalformedURLException {
        return getKieRestServiceClient(getRouteURL()).getServicesClient(clazz);
    }

    /**
     * Valid math operations
     */
    public enum Operation {
        PLUS("+"),
        MINUS("-"),
        TIMES("*"),
        DIVIDE("/");

        private String operator;

        Operation(String operator) {
            this.operator = operator;
        }

        public String operator() {
            return operator;
        }
    }
}
