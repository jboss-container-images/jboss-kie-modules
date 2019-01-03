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

import org.arquillian.cube.openshift.api.OpenShiftResource;
import org.arquillian.cube.openshift.api.Template;
import org.arquillian.cube.openshift.api.TemplateParameter;
import org.jboss.arquillian.container.test.api.Deployment;
import org.jboss.arquillian.junit.Arquillian;
import org.jboss.shrinkwrap.api.spec.WebArchive;
import org.junit.runner.RunWith;

/**
 * @author Filippe Spolti
 */
@RunWith(Arquillian.class)
@Template(url = "https://raw.githubusercontent.com/${template.repository:jboss-container-images}/jboss-processserver-6-openshift-image/${template.branch:master}/templates/processserver64-amq-mysql-s2i.json", parameters = {
        @TemplateParameter(name = "KIE_SERVER_USER", value = "${kie.username:kieserver}"),
        @TemplateParameter(name = "KIE_SERVER_PASSWORD", value = "${kie.password:Redhat@123}"),
        @TemplateParameter(name = "MQ_USERNAME", value = "${mq.username:kieserver}"),
        @TemplateParameter(name = "MQ_PASSWORD", value = "${mq.password:Redhat@123}"),
        @TemplateParameter(name = "MAVEN_MIRROR_URL", value = "${maven.mirror.url}") })
@OpenShiftResource("https://raw.githubusercontent.com/${template.repository:jboss-container-images}/jboss-processserver-6-openshift-image/${template.branch:master}/secrets/processserver-app-secret.json")
public class ProcessServerAmqMySqlTest extends LibraryProcessAmqTestBase {

    @Deployment
    public static WebArchive getDeployment() throws Exception {
        WebArchive war = LibraryProcessAmqTestBase.getDeployment();
        war.addClass(ProcessServerAmqMySqlTest.class);
        return war;
    }

}
