/*
 * JBoss, Home of Professional Open Source
 * Copyright 2016 Red Hat Inc. and/or its affiliates and other
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

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.kie.api.KieServices;
import org.kie.api.command.BatchExecutionCommand;
import org.kie.api.command.Command;
import org.kie.api.command.KieCommands;
import org.kie.api.runtime.ExecutionResults;
import org.kie.api.runtime.rule.QueryResults;
import org.kie.api.runtime.rule.QueryResultsRow;
import org.kie.server.api.marshalling.MarshallerFactory;
import org.kie.server.api.marshalling.MarshallingFormat;
import org.kie.server.api.model.ServiceResponse;
import org.kie.server.client.KieServicesClient;
import org.kie.server.client.KieServicesConfiguration;
import org.kie.server.client.KieServicesFactory;
import org.kie.server.client.ProcessServicesClient;
import org.kie.server.client.RuleServicesClient;
import org.openshift.quickstarts.processserver.library.types.Book;
import org.openshift.quickstarts.processserver.library.types.Loan;
import org.openshift.quickstarts.processserver.library.types.LoanRequest;
import org.openshift.quickstarts.processserver.library.types.LoanResponse;
import org.openshift.quickstarts.processserver.library.types.ReturnRequest;
import org.openshift.quickstarts.processserver.library.types.ReturnResponse;
import org.openshift.quickstarts.processserver.library.types.Suggestion;
import org.openshift.quickstarts.processserver.library.types.SuggestionRequest;
import org.openshift.quickstarts.processserver.library.types.SuggestionResponse;

/**
 * LibraryClient
 * <p/>
 * Client for working with a Library service.
 */
public class LibraryClient {

    private final KieCommands commands = KieServices.Factory.get().getCommands();
    private final KieServicesClient kieServicesClient;

    /**
     * Create a new LibraryClient.
     */
    public LibraryClient(KieServicesConfiguration config) {
        Set<Class<?>> classes = new HashSet<Class<?>>();
        classes.add(Book.class);
        classes.add(Loan.class);
        classes.add(LoanRequest.class);
        classes.add(LoanResponse.class);
        classes.add(ReturnRequest.class);
        classes.add(ReturnResponse.class);
        classes.add(Suggestion.class);
        classes.add(SuggestionRequest.class);
        classes.add(SuggestionResponse.class);
        config.setMarshallingFormat(MarshallingFormat.XSTREAM);
        MarshallerFactory.getMarshaller(classes, config.getMarshallingFormat(),
                Book.class.getClassLoader());
        kieServicesClient = KieServicesFactory.newKieServicesClient(config);
    }

    public Suggestion getSuggestion(String keyword) {
        RuleServicesClient ruleServicesClient = kieServicesClient.getServicesClient(RuleServicesClient.class);
        SuggestionRequest suggestionRequest = new SuggestionRequest();
        suggestionRequest.setKeyword(keyword);
        List<Command<?>> cmds = new ArrayList<Command<?>>();
        cmds.add(commands.newInsert(suggestionRequest));
        cmds.add(commands.newFireAllRules());
        cmds.add(commands.newQuery("suggestion", "get suggestion"));
        BatchExecutionCommand batch = commands.newBatchExecution(cmds, "LibraryRuleSession");
        ExecutionResults execResults;
        ServiceResponse<ExecutionResults> serviceResponse = ruleServicesClient.executeCommandsWithResults(
                "processserver-library", batch);
        // logger.info(String.valueOf(serviceResponse));
        execResults = serviceResponse.getResult();
        QueryResults queryResults = (QueryResults) execResults.getValue("suggestion");
        if (queryResults != null) {
            for (QueryResultsRow queryResult : queryResults) {
                SuggestionResponse suggestionResponse = (SuggestionResponse) queryResult.get("suggestionResponse");
                if (suggestionResponse != null) {
                    return suggestionResponse.getSuggestion();
                }
            }
        }
        return null;
    }

    public Loan attemptLoan(Book book) {
        ProcessServicesClient processServicesClient = kieServicesClient.getServicesClient(ProcessServicesClient.class);
        Map<String, Object> parameters = new HashMap<String, Object>();
        LoanRequest loanRequest = new LoanRequest();
        loanRequest.setIsbn(book.getIsbn());
        parameters.put("loanRequest", loanRequest);
        LoanResponse loanResponse;
        Long pid = processServicesClient.startProcess("processserver-library", "LibraryProcess", parameters);
        loanResponse = (LoanResponse) processServicesClient.getProcessInstanceVariable("processserver-library", pid,
                "loanResponse");
        return loanResponse != null ? loanResponse.getLoan() : null;
    }

    public boolean returnLoan(Loan loan) {
        ProcessServicesClient processServicesClient = kieServicesClient.getServicesClient(ProcessServicesClient.class);
        ReturnRequest returnRequest = new ReturnRequest();
        returnRequest.setLoan(loan);
        ReturnResponse returnResponse;
        processServicesClient.signalProcessInstance("processserver-library", loan.getId(), "ReturnSignal", returnRequest);
        // returnResponse =
        // (ReturnResponse)procserv.getProcessInstanceVariable("processserver-library",
        // loan.getId(), "returnResponse");
        returnResponse = new ReturnResponse();
        returnResponse.setAcknowledged(true);
        return returnResponse != null ? returnResponse.isAcknowledged() : false;
    }

}
