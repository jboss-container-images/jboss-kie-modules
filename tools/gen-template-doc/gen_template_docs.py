#!/usr/bin/env python
# gen_template_doc.py
# Kyle Liberti <kliberti@redhat.com>, Jonathan Dowland <jdowland@redhat.com>, Filippe Spolti<fspolti@redhat.com>
# ver:  Python 3.7
# Desc: Generates application-template documentation by cloning application-template
#       repository, then translating information from template JSON files into
#       template asciidoctor files, and stores them in the a directory(Specified by
#       TEMPLATE_DOCS variable).
#
# Dependencies
#       - ptemplate - pip install ptemplate
#           - this will need a little hack on file  /home/$USER/.local/lib/python3.7/site-packages/ptemplate/formatter.py
#             comment this line: spec = super(Formatter, self)._vformat(token.spec, (), data, (), 2)
#             update the next one by using token.spec instead spec.
#       - pygit2 - dnf install pygit2
#
# Usage
#   Generate docs for RHDM and RHPAM: ./gen_template_docs.py
#   Generate docs only for rhdm: ./gen_template_docs.py --rhdm
#   Generate docs only for rhpam: ./gen_template_docs.py --rhpam
#   Generate docs specifying custom branch: ./gen_template_docs.py --rhdm-git-branch 7.1.0 --rhpam-git-branch 7.1.0
#   Generate docs and copy the docs to its final location:
#       The default location of the generated docs are: ../../../<repo_name>/templates/docs/
#       Considering that jboss-kie-modules and the other projects are in the same directory level, i.e:
#        $ ls  /data/dev/sources
#        ...
#        jboss-processserver-6-openshift-image      rhpam-7-openshift-image
#        And also considering that you are running the tool from jboss-kie-modules/tools/gen-template-doc
#
#       ./gen_template_docs.py --rhdm --copy-docs
#
#       To specify the a custom directory use:  ./gen_template_docs.py --rhdm --copy-docs --rhdm-docs-final-location /my/custom/dir

import argparse
import json
import yaml
import os
import sys
import shutil
import re
from collections import OrderedDict
from pygit2 import clone_repository
from ptemplate.template import Template
from shutil import copy

RHDM_GIT_REPO = "https://github.com/jboss-container-images/rhdm-7-openshift-image.git"
RHPAM_GIT_REPO = "https://github.com/jboss-container-images/rhpam-7-openshift-image.git"
IPS_GIT_REPO = "https://github.com/jboss-container-images/jboss-processserver-6-openshift-image.git"
DS_GIT_REPO = "https://github.com/jboss-container-images/jboss-decisionserver-6-openshift-image.git"
GIT_REPO_LIST = []
REPO_NAME = "application-templates/"
TEMPLATE_DOCS = "output/"
APPLICATION_DIRECTORIES = ("target/rhpam-7-openshift-image", "target/rhdm-7-openshift-image", "output/",
                           "target/jboss-processserver-6-openshift-image", "target/jboss-decisionserver-6-openshift-image")
template_dirs = ['target/rhpam-7-openshift-image/templates', 'target/rhdm-7-openshift-image/templates', 'target/rhdm-7-openshift-image/templates/optaweb',
                 'target/jboss-processserver-6-openshift-image/templates', 'target/jboss-decisionserver-6-openshift-image/templates']

# used to link the image to the image.yaml when the given image is used by a s2i build
LINKS = {"rhdm71-kieserver-openshift:1.0": "../../../kieserver/image.yaml[`rhdm-7/rhdm71-kieserver-openshift`]",
         "rhdm71-kieserver-openshift:1.1": "../../../kieserver/image.yaml[`rhdm-7/rhdm71-kieserver-openshift`]",
         "rhdm72-kieserver-openshift:1.0": "../../../kieserver/image.yaml[`rhdm-7/rhdm72-kieserver-openshift`]",
         "rhdm72-kieserver-openshift:1.1": "../../../kieserver/image.yaml[`rhdm-7/rhdm72-kieserver-openshift`]",
         "rhdm73-kieserver-openshift:1.0": "../../../kieserver/image.yaml[`rhdm-7/rhdm73-kieserver-openshift`]",
         "rhdm73-kieserver-openshift:1.1": "../../../kieserver/image.yaml[`rhdm-7/rhdm73-kieserver-openshift`]",
         "rhdm74-kieserver-openshift:1.0": "../../../kieserver/image.yaml[`rhdm-7/rhdm74-kieserver-openshift`]",
         "rhdm74-kieserver-openshift:1.1": "../../../kieserver/image.yaml[`rhdm-7/rhdm74-kieserver-openshift`]",
         "rhdm-kieserver-rhel8:7.5.0": "../../../kieserver/image.yaml[`rhdm-7/rhdm-kieserver-rhel8`]",
         "rhdm-kieserver-rhel8:7.6.0": "../../../kieserver/image.yaml[`rhdm-7/rhdm-kieserver-rhel8`]",
         "rhdm-kieserver-rhel8:7.7.0": "../../../kieserver/image.yaml[`rhdm-7/rhdm-kieserver-rhel8`]",
         "rhdm-kieserver-rhel8:7.8.0": "../../../kieserver/image.yaml[`rhdm-7/rhdm-kieserver-rhel8`]",
         "rhdm-kieserver-rhel8:7.8.1": "../../../kieserver/image.yaml[`rhdm-7/rhdm-kieserver-rhel8`]",
         "rhdm-kieserver-rhel8:7.9.0": "../../../kieserver/image.yaml[`rhdm-7/rhdm-kieserver-rhel8`]",
         "rhdm-kieserver-rhel8:7.10.0": "../../../kieserver/image.yaml[`rhdm-7/rhdm-kieserver-rhel8`]",
         "rhpam71-kieserver-openshift:1.0": "../../../kieserver/image.yaml[`rhpam-7/rhpam71-kieserver-openshift`]",
         "rhpam71-kieserver-openshift:1.1": "../../../kieserver/image.yaml[`rhpam-7/rhpam71-kieserver-openshift`]",
         "rhpam72-kieserver-openshift:1.0": "../../../kieserver/image.yaml[`rhpam-7/rhpam72-kieserver-openshift`]",
         "rhpam72-kieserver-openshift:1.1": "../../../kieserver/image.yaml[`rhpam-7/rhpam72-kieserver-openshift`]",
         "rhpam73-kieserver-openshift:1.0": "../../../kieserver/image.yaml[`rhpam-7/rhpam73-kieserver-openshift`]",
         "rhpam73-kieserver-openshift:1.1": "../../../kieserver/image.yaml[`rhpam-7/rhpam73-kieserver-openshift`]",
         "rhpam74-kieserver-openshift:1.0": "../../../kieserver/image.yaml[`rhpam-7/rhpam74-kieserver-openshift`]",
         "rhpam74-kieserver-openshift:1.1": "../../../kieserver/image.yaml[`rhpam-7/rhpam74-kieserver-openshift`]",
         "rhpam-kieserver-rhel8:7.5.0": "../../../kieserver/image.yaml[`rhpam-7/rhpam-kieserver-rhel8`]",
         "rhpam-kieserver-rhel8:7.6.0": "../../../kieserver/image.yaml[`rhpam-7/rhpam-kieserver-rhel8`]",
         "rhpam-kieserver-rhel8:7.7.0": "../../../kieserver/image.yaml[`rhpam-7/rhpam-kieserver-rhel8`]",
         "rhpam-kieserver-rhel8:7.8.0": "../../../kieserver/image.yaml[`rhpam-7/rhpam-kieserver-rhel8`]",
         "rhpam-kieserver-rhel8:7.8.1": "../../../kieserver/image.yaml[`rhpam-7/rhpam-kieserver-rhel8`]",
         "rhpam-kieserver-rhel8:7.9.0": "../../../kieserver/image.yaml[`rhpam-7/rhpam-kieserver-rhel8`]",
         "rhpam-kieserver-rhel8:7.10.0": "../../../kieserver/image.yaml[`rhpam-7/rhpam-kieserver-rhel8`]",
         "jboss-processserver64-openshift:1.4": "../../image.yaml[`jboss-processserver64-openshift`]",
         "jboss-processserver64-openshift:1.5": "../../image.yaml[`jboss-processserver64-openshift`]",
         "jboss-processserver64-openshift:1.6": "../../image.yaml[`jboss-processserver64-openshift`]",
         "jboss-decisionserver64-openshift:1.4": "../..iamge.yaml[`jboss-decisionserver64-openshift`]",
         "jboss-decisionserver64-openshift:1.5": "../..iamge.yaml[`jboss-decisionserver64-openshift`]",
         "jboss-decisionserver64-openshift:1.6": "../..iamge.yaml[`jboss-decisionserver64-openshift`]"}

# used to update template parameters values
PARAMETER_VALUES = {"EXAMPLE": "var"}

autogen_warning = """////
    AUTOGENERATED FILE - this file was generated via
    https://github.com/jboss-container-images/jboss-kie-modules/blob/master/tools/gen-template-doc/gen_template_docs.py.
    Changes to .adoc or HTML files may be overwritten! Please change the
    generator or the input template (https://github.com/jboss-container-images/jboss-kie-modules/tree/master/tools/gen-template-doc/*.in)
////
"""

fullname = {
    "rhdm": "Red Hat Decision Manager",
    "rhpam": "Red Hat Process Automation Manager",
}


def generate_templates():
    for directory in template_dirs:
        if not os.path.isdir(directory):
            continue
        for dirpath, dirnames, files in os.walk(directory):
            for template in files:
                if template[-5:] != '.json' and template[-5:] != '.yaml':
                    continue
                generate_template(os.path.join(dirpath, template))


def generate_template(path):
    if "image-stream" in path:
        return
    with open(path) as data_file:
        if path[-5:] == '.json':
            data = json.load(data_file, object_pairs_hook=OrderedDict)
            outfile = TEMPLATE_DOCS + re.sub('\.json$', '',  path.replace('optaweb/', '')) + '.adoc'
        else:
            data = yaml.load(data_file, Loader=yaml.FullLoader)
            outfile = TEMPLATE_DOCS + re.sub('\.yaml$', '',  path.replace('optaweb/', '')) + '.adoc'

    if not 'labels' in data or not "template" in data["labels"]:
        sys.stderr.write("no template label for template %s, can't generate documentation\n" % path)
        return

    outdir = os.path.dirname(outfile)
    if not os.path.exists(outdir):
        os.makedirs(outdir)

    with open(outfile, "w") as text_file:
        print ("Generating %s..." % outfile)
        text_file.write(autogen_warning)
        text_file.write(create_template(data, path))


def create_template(data, path):
    templater = Template()
    templater.template = open('./template.adoc.in').read()

    tdata = {"template": data['labels']['template'], }

    # Fill in the template description, if supplied
    if 'annotations' in data['metadata'] and 'description' in data['metadata']['annotations']:
        tdata['description'] = data['metadata']['annotations']['description']

    # Fill in template parameters table, if there are any
    if ("parameters" in data and "objects" in data) and len(data["parameters"]) > 0:
        tdata['parameters'] = [{'parametertable': create_parameter_table(data)}]

    if "objects" in data:
        tdata['objects'] = [{}]

        # Fill in sections if they are present in the JSON (create_object_table version)
        for kind in ['Service', 'Route', 'BuildConfig', 'PersistentVolumeClaim']:
            if 0 >= len([x for x in data["objects"] if kind == x["kind"]]):
                continue
            tdata['objects'][0][kind] = [{"table": create_object_table(data, kind)}]

        # Fill in sections if they are present in the JSON (create_container_table version)
        for kind in ['image', 'readinessProbe', 'livenessProbe', 'ports', 'env']:
            if 0 >= len([obj for obj in data["objects"] if obj["kind"] == "DeploymentConfig"]):
                continue
            tdata['objects'][0][kind] = [{"table": create_container_table(data, kind)}]

        # Fill in sections if they are present in the JSON (create_deploy_config_table version)
        for kind in ['triggers', 'replicas', 'volumes', 'serviceAccountName']:
            if 0 >= len([obj for obj in data["objects"] if obj["kind"] == "DeploymentConfig"]):
                continue

            if kind in ['volumes', 'serviceAccountName']:
                specs = [d["spec"]["template"]["spec"] for d in data["objects"] if d["kind"] == "DeploymentConfig"]
                matches = [spec[kind] for spec in specs if spec.get(kind) is not None]
                if len(matches) <= 0:
                    continue
            tdata['objects'][0][kind] = [{"table": create_deploy_config_table(data, kind)}]

        # the 'secrets' section is not relevant to the secrets templates
        if not re.match('^secrets', path):
            specs = [d["spec"]["template"]["spec"] for d in data["objects"] if d["kind"] == "DeploymentConfig"]
            service_account_name = [spec["serviceAccountName"] for spec in specs if
                                  spec.get("serviceAccountName") is not None]
            # only include the secrets section if we have defined serviceAccount(s)
            secret_name = ""
            if len(service_account_name) > 0:
                for param in data["parameters"]:
                    if "example" in param:
                        if not isinstance(param["example"], int) and param["example"].endswith("app-secret"):
                            secret_name += ' * ' + param["example"] + '\n'
                    elif "value" in param and param["value"].endswith("app-secret"):
                        secret_name += ' * ' + param["value"] + '\n'
                tdata['objects'][0]['secrets'] = [{"secretNames": secret_name}]

        # Any template that supports clustering needs to be added in the clusteringTemplates var.
        clustering_templates = [
            'rhpam70-authoring-ha.yaml',
            'rhpam71-authoring-ha.yaml', 'rhdm71-authoring-ha.yaml',
            'rhpam72-authoring-ha.yaml', 'rhdm72-authoring-ha.yaml',
            'rhpam73-authoring-ha.yaml', 'rhdm73-authoring-ha.yaml',
            'rhpam74-authoring-ha.yaml', 'rhdm74-authoring-ha.yaml',
            'rhpam75-authoring-ha.yaml', 'rhdm75-authoring-ha.yaml',
            'rhpam76-authoring-ha.yaml', 'rhdm76-authoring-ha.yaml',
            'rhpam77-authoring-ha.yaml', 'rhdm77-authoring-ha.yaml',
            'rhpam78-authoring-ha.yaml', 'rhdm78-authoring-ha.yaml',
            'rhpam79-authoring-ha.yaml', 'rhdm79-authoring-ha.yaml',
            'rhpam710-authoring-ha.yaml', 'rhdm710-authoring-ha.yaml'
        ]
        for template in clustering_templates:
            if str(path).rsplit('/', 1)[-1] == template:
                tdata['objects'][0]['clustering'] = [{}]
    return templater.render(tdata)


def possibly_fix_width(text):
    """Heuristic to possibly mark-up text as monospaced if it looks like
       a URL, or an environment variable name, etc."""

    if text in ['', '--']:
        return text

    # stringify the arguments
    if type(text) not in [type('string'), type(u'Unicode')]:
        text = "%r" % text

    if text[0] in "$/" or "}" == text[-1] or re.match(r'^[A-Z_\${}:-]+$', text):
        return '`%s`' % text

    return text


def build_row(columns):
    return "\n|" + " | ".join(map(possibly_fix_width, columns))


def get_volume_purpose(name):
    name = name.split("-")
    if ("certificate" in name or "keystore" in name or "secret" in name):
        return "ssl certs"
    elif ("amq" in name):
        return "kahadb"
    elif ("pvol" in name):
        return name[1]
    else:
        return "--"


# Used for getting image environment variables into parameters table and parameter
# descriptions into image environment table
def get_variable_info(parameters, name, env, field):

    for d in parameters:
        try:
            if len(env) > 0 and field == 'description':
                env_value = replacer(env["value"])

                if d['name'] == env_value or d["name"] == env['name']:
                    return str(d[field]).replace("|", "\\|")

            elif d["name"] == name and name != "":
                if field == "value" and "example" in d:
                    return d["example"]
                elif field == "value" and not "example" in d and not d.get(field):
                    return "--"

                return str(d[field]).replace("|", "\\|")

            else:
                parameter_value = replacer(d["value"])
                if parameter_value == name and field == 'value':
                    return d[field]

                elif parameter_value == name:
                    return d["name"]

        except KeyError:
            pass

    if field == "value" and name in PARAMETER_VALUES.keys():
        return PARAMETER_VALUES[name]
    else:
        return "--"


def create_parameter_table(data):
    text = ""
    for param in data["parameters"]:
        if u"\u2019" in param["description"]:
            param["description"] = param["description"].replace(u"\u2019", "'")

        container_envs = [d["spec"]["template"]["spec"]["containers"][0]["env"] for d in data["objects"] if ( d["kind"] == "DeploymentConfig" and "env" in d["spec"]["template"]["spec"]["containers"][0])]
        parameters = [item for sublist in container_envs for item in sublist]
        env_var = get_variable_info(parameters, param["name"], [], "name")
        value = param["value"] if param.get("value") else get_variable_info(data['parameters'], param["name"], [], "value")
        req = param["required"] if "required" in param else "?"
        columns = [param["name"], env_var, str(param["description"]).replace("|", "\\|"), value, req]
        text += build_row(columns)
    return text


def create_object_table(data, tableKind):
    text = ""
    columns = []
    for obj in data["objects"]:
        if obj["kind"] == 'Service' and tableKind == 'Service':
            add_description = True
            ports = obj["spec"]["ports"]
            text += "\n." + str(len(ports)) + "+| `" + obj["metadata"]["name"] + "`"
            for p in ports:
                columns = ["port", "name"]
                columns = [str(p[col]) if p.get(col) else "--" for col in columns]
                text += build_row(columns)
                if add_description:
                    text += "\n." + str(len(ports)) + "+| " + obj["metadata"]["annotations"]["description"]
                    add_description = False
            continue
        elif obj["kind"] == 'Route' and tableKind == 'Route':
            hostname = "<default>"
            if "host" in obj["spec"]:
                hostname = obj["spec"]["host"]
            if (obj["spec"].get("tls")):
                columns = [obj["id"], ("TLS " + obj["spec"]["tls"]["termination"]), hostname]
            else:
                columns = [obj["id"], "none", hostname]
        elif obj["kind"] == 'BuildConfig' and tableKind == 'BuildConfig':
            if obj["spec"]["strategy"]["type"] == 'Source':
                s2i = obj["spec"]["strategy"]["sourceStrategy"]["from"]["name"]
                tempS2i = s2i.split(":")
                if "${" in tempS2i[0]:
                    varName = tempS2i[0][tempS2i[0].find("{") + 1:tempS2i[0].find("}")]
                    varValue = get_variable_info(data['parameters'], varName, [], "value")
                    s2i = s2i.replace('${' + varName + '}', varValue)
                if "${" in tempS2i[1]:
                    varName = tempS2i[1][tempS2i[1].find("{") + 1:tempS2i[1].find("}")]
                    varValue = get_variable_info(data['parameters'], varName, [], "value")
                    s2i = s2i.replace('${' + varName + '}', varValue)
                link = " link:" + LINKS[s2i]
            elif obj["spec"]["strategy"]["type"] == 'Docker':
                s2i = obj["spec"]["strategy"]["dockerStrategy"]["dockerfilePath"]
                link = ""
            columns = [s2i, link, obj["spec"]["output"]["to"]["name"],
                       ", ".join([x["type"] for x in obj["spec"]["triggers"]])]
        elif obj["kind"] == 'PersistentVolumeClaim' and tableKind == 'PersistentVolumeClaim':
            columns = [obj["metadata"]["name"], obj["spec"]["accessModes"][0]]
        if (obj["kind"] == tableKind):
            text += build_row(columns)
    return text


def create_deploy_config_table(data, table):
    text = ""
    deployment_config = (obj for obj in data["objects"] if obj["kind"] == "DeploymentConfig")
    for obj in deployment_config:
        columns = []
        deployment = obj["metadata"]["name"]
        spec = obj["spec"]
        template = spec["template"]["spec"]
        if template.get(table) or spec.get(table):
            if table == "triggers":
                columns = [deployment, spec["triggers"][0]["type"]]
            elif table == "replicas":
                # correctly identify integer values from parameter value
                if "${" in str(spec["replicas"]):
                    replica_env = replacer(str(spec["replicas"]))
                    for p in data['parameters']:
                        if p['name'] == replica_env:
                            columns = [ deployment, p['value'] ]
                else:
                    columns = [ deployment, str(spec["replicas"]) ]
            elif table == "serviceAccountName":
                columns = [deployment, template["serviceAccountName"]]
            elif table == "volumes":
                volume_mount = obj["spec"]["template"]["spec"]["containers"][0]["volumeMounts"][0]
                name = template["volumes"][0]["name"]
                read_only = str(volume_mount["readOnly"]) if "readOnly" in volume_mount else "false"
                columns = [deployment, name, volume_mount["mountPath"], get_volume_purpose(name), read_only]
            text += build_row(columns)
    return text


def create_container_table(data, table):
    text = ""
    deployment_config = (obj for obj in data["objects"] if obj["kind"] == "DeploymentConfig")
    for obj in deployment_config:
        columns = []
        deployment = obj["metadata"]["name"]
        container = obj["spec"]["template"]["spec"]["containers"][0]
        if table == "image":
            columns = [deployment, container["image"]]
            text += build_row(columns)
        elif table == "readinessProbe":
            if container.get("readinessProbe"):
                if 'httpGet' in container["readinessProbe"]:
                    text += ("\n." + deployment + "\n----\n" \
                             + "".join(
                                "Http Get on http://localhost:" + str(container["readinessProbe"]["httpGet"]["port"])) \
                             + "".join(container["readinessProbe"]["httpGet"]["path"]) \
                             + "\n----\n")
                elif 'exec' in container["readinessProbe"]:
                    text += ("\n." + deployment + "\n----\n" \
                             + " ".join(container["readinessProbe"]["exec"]["command"]) \
                             + "\n----\n")
                elif 'tcpSocket' in container["readinessProbe"]:
                    text += ("\n." + deployment + "\n----\n" \
                             + "".join("tcpSocket on port " + str(container["readinessProbe"]["tcpSocket"]["port"])) \
                             + "\n----\n")

        elif table == "livenessProbe":
            if 'livenessProbe' in container:
                if 'httpGet' in container["livenessProbe"]:
                    text += ("\n." + deployment + "\n----\n" \
                             + "".join(
                                "Http Get on http://localhost:" + str(container["livenessProbe"]["httpGet"]["port"])) \
                             + "".join(container["livenessProbe"]["httpGet"]["path"]) \
                             + "\n----\n")
                elif 'exec' in container["livenessProbe"]:
                    text += ("\n." + deployment + "\n----\n" \
                             + " ".join(container["livenessProbe"]["exec"]["command"]) \
                             + "\n----\n")
                elif 'tcpSocket' in container["livenessProbe"]:
                    text += ("\n." + deployment + "\n----\n" \
                             + "".join("tcpSocket on port " + str(container["livenessProbe"]["tcpSocket"]["port"])) \
                             + "\n----\n")

        elif table == "ports" and "ports" in container:
            text += "\n." + str(len(container["ports"])) + "+| `" + deployment + "`"
            ports = container["ports"]
            for p in ports:
                columns = ["name", "containerPort", "protocol"]
                columns = [str(p[col]) if p.get(col) else "--" for col in columns]
                text += build_row(columns)
        elif table == "env" and "env" in container:
            environment = container["env"]
            text += "\n." + str(len(environment)) + "+| `" + deployment + "`"
            for env in environment:
                columns = [env["name"], get_variable_info(data["parameters"], "", env, "description")]

                # TODO: handle valueFrom instead of value
                if "value" in env:
                    columns.append(env["value"])
                else:
                    columns.append("--")
                text += build_row(columns)
    return text


def replacer(string):
    return re.sub("['$','{','}']","", string)


def generate_readme(generate_rhdm, generate_rhpam, generate_ips, generate_ds):
    black_list = ['contrib', 'docs', 'optaweb']
    """Generates a README page for the template documentation."""
    if generate_rhdm:
        try:
            with open('output/target/rhdm-7-openshift-image/README.adoc', 'w') as fh:
                print('Generating output/target/rhdm-7-openshift-image/README.adoc...')
                fh.write(autogen_warning)
                # page header
                fh.write(open('./README_RHDM.adoc.in').read())
                for directory in sorted(template_dirs):
                    if not os.path.isdir(directory):
                        continue
                    elif "rhdm" in directory:
                        # section header
                        prefix = ''
                        if "optaweb" in directory:
                            prefix = 'optaweb-'
                        fh.write('\n== %s%s\n\n' % (prefix, "rhdm-7-openshift-image/templates"))
                        # links
                        for template in [os.path.splitext(x)[0] for x in sorted(os.listdir(directory))]:
                            if "image-stream" not in template and template not in black_list:
                                fh.write("* link:%s.adoc[%s]\n" % (template, template))
                # release notes
                fh.write(open('./release-notes-rhdm.adoc.in').read())
        except IOError as err:
            print("Error while writing README_RHDM.adoc: " + str(err))
            pass

    if generate_rhpam:
        try:
            with open('output/target/rhpam-7-openshift-image/README.adoc', 'w') as fh:
                print('Generating output/target/rhpam-7-openshift-image/README.adoc...')
                fh.write(autogen_warning)
                # page header
                fh.write(open('./README_RHPAM.adoc.in').read())

                for directory in sorted(template_dirs):
                    if not os.path.isdir(directory):
                        continue
                    elif "rhpam" in directory:
                        # section header
                        fh.write('\n== %s\n\n' % "rhpam-7-openshift-image/templates")

                        # links
                        for template in [os.path.splitext(x)[0] for x in sorted(os.listdir(directory))]:
                            if "image-stream" not in template and template not in black_list:
                                fh.write("* link:%s.adoc[%s]\n" % (template, template))
                # release notes
                fh.write(open('./release-notes-rhpam.adoc.in').read())
        except IOError as err:
            print("Error while writing README_RHPAM.adoc: " + str(err))
            pass

    if generate_ips:
        try:
            with open('output/target/jboss-processserver-6-openshift-image/README.adoc', 'w') as fh:
                print('Generating output/target/jboss-processserver-6-openshift-image/README.adoc...')
                fh.write(autogen_warning)
                # page header
                fh.write(open('./README_IPS.adoc.in').read())

                for directory in sorted(template_dirs):
                    if not os.path.isdir(directory):
                        continue
                    elif "processserver" in directory:
                        # section header
                        fh.write('\n== %s\n\n' % "jboss-processserver-6-openshift-image/templates")
                        # links
                        for template in [os.path.splitext(x)[0] for x in sorted(os.listdir(directory))]:
                            if template != "processserver-app-secret" and "image-stream" not in template and template not in black_list:
                                fh.write("* link:%s.adoc[%s]\n" % (template, template))
                # release notes
                fh.write(open('./release-notes-ips.adoc.in').read())
        except IOError as err:
            print("Error while writing README_IPS.adoc: " + str(err))
            pass

    if generate_ds:
        try:
            with open('output/target/jboss-decisionserver-6-openshift-image/README.adoc', 'w') as fh:
                print('Generating output/target/jboss-decisionserver-6-openshift-image/README.adoc...')
                fh.write(autogen_warning)
                # page header
                fh.write(open('./README_DS.adoc.in').read())

                for directory in sorted(template_dirs):
                    if not os.path.isdir(directory):
                        continue
                    elif "decisionserver" in directory:
                        # section header
                        fh.write('\n== %s\n\n' % "jboss-decisionserver-6-openshift-image/templates")
                        # links
                        for template in [os.path.splitext(x)[0] for x in sorted(os.listdir(directory))]:
                            if "image-stream" not in template and template not in black_list:
                                fh.write("* link:%s.adoc[%s]\n" % (template, template))
                # release notes
                fh.write(open('./release-notes-ds.adoc.in').read())
        except IOError as err:
            print("Error while writing README_DS.adoc: " + str(err))
            pass


def pull_templates(rhdm_git_branch, rhpam_git_branch, ips_git_branch, ds_git_branch):
    print('Pulling templates from {0}'.format(GIT_REPO_LIST))
    try:
        for dir in APPLICATION_DIRECTORIES:
            shutil.rmtree(dir, ignore_errors=True)

    except OSError as e:
        print("Error: %s - %s." % (e.filename, e.strerror))

    for repo in GIT_REPO_LIST:
        git_dir = 'target/' + repo.rsplit('/', 1)[-1].replace('.git', '')
        if 'rhdm' in git_dir:
            print('Using RHDM branch {0}'.format(rhdm_git_branch))
            clone_repository(repo, git_dir, bare=False, checkout_branch=rhdm_git_branch)
        elif 'rhpam' in git_dir:
            print('Using RHPAM branch {0}'.format(rhpam_git_branch))
            clone_repository(repo, git_dir, bare=False, checkout_branch=rhpam_git_branch)
        elif 'processserver' in git_dir:
            print('Using IPS branch {0}'.format(ips_git_branch))
            clone_repository(repo, git_dir, bare=False, checkout_branch=ips_git_branch)
        elif 'decisionserver' in git_dir:
            print('Using DS branch {0}'.format(ds_git_branch))
            clone_repository(repo, git_dir, bare=False, checkout_branch=ds_git_branch)


def copy_templates_from_local_fs(local_fs):
    base_target_dir = 'target'
    try:
        print('Copying templates from {0}'.format(local_fs))
        for dir in APPLICATION_DIRECTORIES:
            shutil.rmtree(dir, ignore_errors=True)

        shutil.rmtree(base_target_dir, ignore_errors=True)
        shutil.copytree(local_fs, os.path.join(base_target_dir, str(os.path.basename(local_fs))),
                        symlinks=False, ignore=None)
    except OSError as err:
        print("Error while copying templates from %s: %s." % (local_fs, err))


def copy_templates_adoc(generate_rhdm, generate_rhpam, generate_ips, generate_ds,
                        rhdm_docs_final_location, rhpam_docs_final_location,
                        ips_docs_final_location, ds_docs_final_location):

    for project in APPLICATION_DIRECTORIES:
        if generate_rhdm and "rhdm" in project:
            try:
                for dirpath, dirnames, files in os.walk(TEMPLATE_DOCS + "" + project):
                    for template in files:
                        if template[-5:] != '.adoc':
                            continue
                        print('Copying file {0} to {1}'.format(os.path.join(dirpath, template), rhdm_docs_final_location))
                        copy(os.path.join(dirpath, template), rhdm_docs_final_location)
            except IOError as err:
                print("Error while copying RHDM adocs: " + str(e))
                pass

        if generate_rhpam and "rhpam" in project:
            try:
                for dirpath, dirnames, files in os.walk(TEMPLATE_DOCS + "" + project):
                    for template in files:
                        if template[-5:] != '.adoc':
                            continue
                        print('Copying file {0} to {1}'.format(os.path.join(dirpath, template),
                                                               rhpam_docs_final_location))
                        copy(os.path.join(dirpath, template), rhpam_docs_final_location)
            except IOError as err:
                print("Error while copying RHPAM adocs: " + str(e))
                pass

        if generate_ips and "processserver" in project:
            try:
                for dirpath, dirnames, files in os.walk(TEMPLATE_DOCS + "" + project):
                    for template in files:
                        if template[-5:] != '.adoc':
                            continue
                        print('Copying file {0} to {1}'.format(os.path.join(dirpath, template),
                                                               ips_docs_final_location))
                        copy(os.path.join(dirpath, template), ips_docs_final_location)
            except IOError as err:
                print("Error while copying RHPAM adocs: " + str(err))
                pass

        if generate_ds and "decisionserver in":
            try:
                for dirpath, dirnames, files in os.walk(TEMPLATE_DOCS + "" + project):
                    for template in files:
                        if template[-5:] != '.adoc':
                            continue
                        print('Copying file {0} to {1}'.format(os.path.join(dirpath, template), ds_docs_final_location))
                        copy(os.path.join(dirpath, template), ds_docs_final_location)
            except IOError as err:
                print("Error while copying RHPAM adocs: " + str(err))
                pass


# expects to be run from the root of the repository
if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='OpenShift Application Templates docs generator')
    parser.add_argument('--local-fs', dest='local_fs', default=None, help='Specify a local directory to get the '
                                                                          'Application templates from. Use the root '
                                                                          'directory.')
    parser.add_argument('--rhdm-git-branch', dest='rhdm_git_branch', default='master', help='Branch to checkout')
    parser.add_argument('--rhpam-git-branch', dest='rhpam_git_branch', default='master', help='Branch to checkout')
    parser.add_argument('--ips-git-branch', dest='ips_git_branch', default='6.4.x', help='Branch to checkout')
    parser.add_argument('--ds-git-branch', dest='ds_git_branch', default='6.4.x', help='Branch to checkout')
    parser.add_argument('--rhdm', dest='generate_rhdm', action='store_true', default=False,
                        help='If set, only rhdm template docs will be generated')
    parser.add_argument('--rhpam', dest='generate_rhpam', action='store_true', default=False,
                        help='If set, only rhpam template docs will be generated')
    parser.add_argument('--ips', dest='generate_ips', action='store_true', default=False,
                        help='If set, only IPS template docs will be generated')
    parser.add_argument('--ds', dest='generate_ds', action='store_true', default=False,
                        help='If set, only IPS template docs will be generated')

    parser.add_argument('--copy-docs', dest='copy_docs', action='store_true', default=False,
                        help='If set, the generated docs will be copied to the defined final directory '
                             'defined by the --rhdm-docs-final-location, --rhpam-docs-final-location,'
                             '--ips-docs-final-location and --ds-docs-final-location')
    parser.add_argument('--rhdm-docs-final-location', dest='rhdm_docs_final_location',
                        default='../../../rhdm-7-openshift-image/templates/docs/',
                        help='RHDM final docs location, this directory will be used to copy the generated docs.'
                             'The default location is defined based on this script root\'s directory.')
    parser.add_argument('--rhpam-docs-final-location', dest='rhpam_docs_final_location',
                        default='../../../rhpam-7-openshift-image/templates/docs/',
                        help='RHPAM final docs location, this directory will be used to copy the generated docs.'
                             'The default location is defined based on this script root\'s directory.')
    parser.add_argument('--ips-docs-final-location', dest='ips_docs_final_location',
                        default='../../../jboss-processserver-6-openshift-image/templates/docs/',
                        help='IPS final docs location, this directory will be used to copy the generated docs.'
                             'The default location is defined based on this script root\'s directory.')
    parser.add_argument('--ds-docs-final-location', dest='ds_docs_final_location',
                        default='../../../jboss-decisionserver-6-openshift-image/templates/docs/',
                        help='DS final docs location, this directory will be used to copy the generated docs.'
                             'The default location is defined based on this script root\'s directory.')

    parser.add_argument('--template', dest='template', help='Generate the docs for only one template')
    args = parser.parse_args()

    if not args.generate_rhdm and not args.generate_rhpam and not args.generate_ips and not args.generate_ds:
        GIT_REPO_LIST = [RHDM_GIT_REPO, RHPAM_GIT_REPO, IPS_GIT_REPO, DS_GIT_REPO]
        # when no args are provided the default behavior is generate docs for pam and dm
        # so, here the values for args.generate_rhdm and args.generate_rhpam
        # are manually set.
        args.generate_rhdm = True
        args.generate_rhpam = True
        args.generate_ds = True
        args.generate_ips = True

    elif args.generate_rhdm:
        GIT_REPO_LIST.append(RHDM_GIT_REPO)
    elif args.generate_rhpam:
        GIT_REPO_LIST.append(RHPAM_GIT_REPO)
    elif args.generate_ips:
        GIT_REPO_LIST.append(IPS_GIT_REPO)
    elif args.generate_ds:
        GIT_REPO_LIST.append(DS_GIT_REPO)
    # the user may specify a particular template to parse,
    if args.template:
        generate_template(args.template)
    # otherwise we'll look for them all (and do an index)
    else:
        # clean everything generated before
        try:
            shutil.rmtree('docs', ignore_errors=True)
        except OSError as e:
            print("Error: %s - %s." % ('docs', e.strerror))

        if args.local_fs:
            # copy templates from local fs
            copy_templates_from_local_fs(args.local_fs)
        else:
            # pull all the templates from upstream
            pull_templates(args.rhdm_git_branch, args.rhpam_git_branch, args.ips_git_branch, args.ds_git_branch)

        generate_templates()
        generate_readme(args.generate_rhdm, args.generate_rhpam, args.generate_ips, args.generate_ds)

        if args.copy_docs:
            copy_templates_adoc(args.generate_rhdm, args.generate_rhpam, args.generate_ips, args.generate_ds,
                                args.rhdm_docs_final_location, args.rhpam_docs_final_location,
                                args.ips_docs_final_location, args.ds_docs_final_location)
