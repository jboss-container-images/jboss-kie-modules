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

import java.net.URL;

import org.arquillian.cube.openshift.impl.enricher.RouteURL;
import org.jboss.arquillian.ce.shrinkwrap.Libraries;
import org.jboss.arquillian.container.test.api.RunAsClient;
import org.jboss.shrinkwrap.api.spec.WebArchive;
import org.jboss.test.arquillian.ce.common.KieServerTestBase;
import org.junit.Assert;
import org.junit.Test;
import org.kie.server.client.KieServicesConfiguration;
import org.openshift.quickstarts.processserver.library.types.Book;
import org.openshift.quickstarts.processserver.library.types.Loan;
import org.openshift.quickstarts.processserver.library.types.Suggestion;

/**
 * @author Filippe Spolti
 */
public abstract class LibraryProcessTestBase extends KieServerTestBase {

    @RouteURL("kie-app")
    private URL routeURL;

    public static WebArchive getDeployment() throws Exception {
        WebArchive war = getDeploymentInternal();
        war.addAsLibraries(Libraries.transitive("org.apache.activemq", "activemq-all"));
        war.addPackage("org.openshift.quickstarts.processserver.library.types");
        war.addClass(LibraryClient.class);
        war.addClass(LibraryProcessTestBase.class);
        return war;
    }

    @Override
    protected URL getRouteURL() {
        return routeURL;
    }

    @Test
    public void testLibraryREST() throws Exception {
        runLibraryTest(configureRestClient(new URL("http://" + System.getenv("KIE_APP_SERVICE_HOST") + ":" + System.getenv("KIE_APP_SERVICE_PORT") + "/")));
    }

    @Test
    @RunAsClient
    public void testLibraryRESTRemote() throws Exception {
        runLibraryTest(configureRestClient(getRouteURL()));
    }
    
    protected void runLibraryTest(KieServicesConfiguration kiecfg) {
        LibraryClient client = new LibraryClient(kiecfg);

        Suggestion suggestion1_Zombie = client.getSuggestion("Zombie War");
        Book book1_WorldWarZ = suggestion1_Zombie.getBook();
        log.info("Received suggestion for book: " + book1_WorldWarZ.getTitle() + " (isbn: " + book1_WorldWarZ.getIsbn()
                + ")");
        Assert.assertEquals("World War Z", book1_WorldWarZ.getTitle());
        // take out 1st loan
        log.info("Attempting 1st loan for isbn: " + book1_WorldWarZ.getIsbn());
        Loan loan1_WorldWarZ = client.attemptLoan(book1_WorldWarZ);
        log.info("1st loan approved? " + loan1_WorldWarZ.isApproved());
        Assert.assertTrue(loan1_WorldWarZ.isApproved());
        Loan loan2_WorldWarZ = client.attemptLoan(book1_WorldWarZ);
        log.info("2nd loan approved? " + loan1_WorldWarZ.isApproved());
        Assert.assertTrue(!loan2_WorldWarZ.isApproved());
        boolean returned = client.returnLoan(loan1_WorldWarZ);
        log.info("Returned? " + returned);
        Assert.assertTrue(returned);
    }
}