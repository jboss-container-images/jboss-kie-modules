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

import java.net.URL;

import org.arquillian.cube.openshift.api.OpenShiftResource;
import org.arquillian.cube.openshift.api.Template;
import org.arquillian.cube.openshift.api.TemplateParameter;
import org.arquillian.cube.openshift.api.Tools;
import org.arquillian.cube.openshift.shrinkwrap.Libraries;
import org.jboss.arquillian.container.test.api.Deployment;
import org.jboss.arquillian.junit.Arquillian;
import org.jboss.shrinkwrap.api.spec.WebArchive;
import org.junit.Test;
import org.junit.runner.RunWith;

import io.fabric8.utils.Base64Encoder;

/**
 * @author fspolti
 */

@RunWith(Arquillian.class)
@Template(url = "https://raw.githubusercontent.com/${template.repository:jboss-container-images}/jboss-decisionserver-6-openshift-image/${template.branch:master}/templates/decisionserver64-https-s2i.json",
        parameters = {
                //the Containers list will be sorted in alphabetical order
                @TemplateParameter(name = "KIE_CONTAINER_DEPLOYMENT", value = "decisionserver-hellorules=org.openshift.quickstarts:decisionserver-hellorules:1.4.0.Final|" +
                        "AnotherContainer=org.openshift.quickstarts:decisionserver-hellorules:1.4.0.Final"),
                @TemplateParameter(name = "KIE_SERVER_USER", value = "${kie.username:kieserver}"),
                @TemplateParameter(name = "KIE_SERVER_PASSWORD", value = "${kie.password:Redhat@123}"),
                @TemplateParameter(name = "MAVEN_MIRROR_URL", value = "${maven.mirror.url}")
        }
)
@OpenShiftResource("https://raw.githubusercontent.com/${template.repository:jboss-container-images}/jboss-decisionserver-6-openshift-image/${template.branch:master}/secrets/decisionserver-app-secret.json")
public class DecisionServerHttpClientSecureAllInOneTest extends DecisionServerTestBase {

    @Deployment
    public static WebArchive getDeployment() throws Exception {
        WebArchive war = getDeploymentInternal();
        war.addClass(Base64Encoder.class);
        return war;
    }

    @Override
    protected URL getRouteURL() {
        // no client side tests
        return null;
    }

    @Test
    public void testDecisionServerCapabilitiesHttpClient() {
        checkDecisionServerCapabilitiesHttpClient();
    }

    @Test
    public void testDecisionServerSecureMultiContainerHttpClient() {
        checkDecisionServerSecureMultiContainerHttpClient();
    }

    @Test
    public void testFireAllRulesSecureHttpClient() throws Exception {
        checkFireAllRulesSecureHttpClient();
    }

    @Test
    public void testFireAllRulesSecureSecondContainerHttpClient() throws Exception {
        checkFireAllRulesSecureSecondContainerHttpClient();
    }
//
//    /**
//     * only needed for non-production test scenarios
//     */
//    @Override
//    protected void prepareClientInvocation() {
//        try {
//            System.setProperty("https.protocols", "TLSv1,TLSv1.1,TLSv1.2");
//            Tools.trustAllCertificates();
//        } catch (Exception e) {
//            e.printStackTrace();
//        }
//        log.info("Trusting all certs");
//    }
}
