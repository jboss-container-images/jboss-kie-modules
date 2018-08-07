#!/usr/bin/env python
# gen_template_doc.py
# Kyle Liberti <kliberti@redhat.com>, Jonathan Dowland <jdowland@redhat.com>, Filippe Spolti<fspolti@redhat.com>
# ver:  Python 2.7
# Desc: Generates application-template documentation by cloning application-template 
#       repository, then translating information from template JSON files into 
#       template asciidoctor files, and stores them in the a directory(Specified by
#       TEMPLATE_DOCS variable).
#
# Dependencies
#       - ptemplate - pip install ptemplate
#       - pygit2 - dnf install pygit2
#
# Usage
#   Generate docs for RHDM and RHPAM: ./gen_template_docs.py
#   Generate docs only for rhdm: ./gen_template_docs.py --rhdm
#   Generate docs only for rhpam: ./gen_template_docs.py --rhpam
#   Generate docs specifying custom branch: ./gen_template_docs.py --rhdm-git-branch 7.1.0 --rhpam-git-branch 7.1.0

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

RHDM_GIT_REPO = "https://github.com/jboss-container-images/rhdm-7-openshift-image.git"
RHPAM_GIT_REPO = "https://github.com/jboss-container-images/rhpam-7-openshift-image.git"
GIT_REPO_LIST = ''
REPO_NAME = "application-templates/"
TEMPLATE_DOCS = "docs/"
APPLICATION_DIRECTORIES = ("rhpam-7-openshift-image", "rhdm-7-openshift-image", "docs")
template_dirs = ['rhpam-7-openshift-image/templates', 'rhdm-7-openshift-image/templates']

# used to link the image to the image.yaml when the given image is used by a s2i build
LINKS = {"rhdm71-kieserver-openshift:1.0": "../../../kieserver/image.yaml[`rhdm-7/rhdm71-kieserver-openshift`]",
         "rhpam71-kieserver-openshift:1.0": "../../../kieserver/image.yaml[`rhpam-7/rhpam71-kieserver-openshift`]"}

# used to update template parameters values
PARAMETER_VALUES = {"EXAMPLE": "var"}

autogen_warning = """////
    AUTOGENERATED FILE - this file was generated via ./tools/gen_template_docs.py.
    Changes to .adoc or HTML files may be overwritten! Please change the
    generator or the input template (./*.in)
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
        for template in sorted(os.listdir(directory)):
            if template[-5:] != '.json' and template[-5:] != '.yaml':
                continue
            generate_template(os.path.join(directory, template))


def generate_template(path):
    if "image-stream" in path:
        return
    with open(path) as data_file:
        if path[-5:] == '.json':
            data = json.load(data_file, object_pairs_hook=OrderedDict)
            outfile = TEMPLATE_DOCS + re.sub('\.json$', '', path) + '.adoc'
        else:
            data = yaml.load(data_file)
            outfile = TEMPLATE_DOCS + re.sub('\.yaml$', '', path) + '.adoc'

    if not 'labels' in data or not "template" in data["labels"]:
        sys.stderr.write("no template label for template %s, can't generate documentation\n" % path)
        return

    outdir = os.path.dirname(outfile)
    if not os.path.exists(outdir):
        os.makedirs(outdir)

    with open(outfile, "w") as text_file:
        print ("Generating %s..." % outfile)
        text_file.write(autogen_warning)
        text_file.write(createTemplate(data, path))


def createTemplate(data, path):
    templater = Template()
    templater.template = open('./template.adoc.in').read()

    tdata = {"template": data['labels']['template'], }

    # Fill in the template description, if supplied
    if 'annotations' in data['metadata'] and 'description' in data['metadata']['annotations']:
        tdata['description'] = data['metadata']['annotations']['description']

    # Fill in template parameters table, if there are any
    if ("parameters" in data and "objects" in data) and len(data["parameters"]) > 0:
        tdata['parameters'] = [{'parametertable': createParameterTable(data)}]

    if "objects" in data:
        tdata['objects'] = [{}]

        # Fill in sections if they are present in the JSON (createObjectTable version)
        for kind in ['Service', 'Route', 'BuildConfig', 'PersistentVolumeClaim']:
            if 0 >= len([x for x in data["objects"] if kind == x["kind"]]):
                continue
            tdata['objects'][0][kind] = [{"table": createObjectTable(data, kind)}]

        # Fill in sections if they are present in the JSON (createContainerTable version)
        for kind in ['image', 'readinessProbe', 'livenessProbe', 'ports', 'env']:
            if 0 >= len([obj for obj in data["objects"] if obj["kind"] == "DeploymentConfig"]):
                continue
            tdata['objects'][0][kind] = [{"table": createContainerTable(data, kind)}]

        # Fill in sections if they are present in the JSON (createDeployConfigTable version)
        for kind in ['triggers', 'replicas', 'volumes', 'serviceAccountName']:
            if 0 >= len([obj for obj in data["objects"] if obj["kind"] == "DeploymentConfig"]):
                continue

            if kind in ['volumes', 'serviceAccountName']:
                specs = [d["spec"]["template"]["spec"] for d in data["objects"] if d["kind"] == "DeploymentConfig"]
                matches = [spec[kind] for spec in specs if spec.get(kind) is not None]
                if len(matches) <= 0:
                    continue
            tdata['objects'][0][kind] = [{"table": createDeployConfigTable(data, kind)}]

        # the 'secrets' section is not relevant to the secrets templates
        if not re.match('^secrets', path):
            specs = [d["spec"]["template"]["spec"] for d in data["objects"] if d["kind"] == "DeploymentConfig"]
            serviceAccountName = [spec["serviceAccountName"] for spec in specs if
                                  spec.get("serviceAccountName") is not None]
            # only include the secrets section if we have defined serviceAccount(s)
            secretName = ""
            if len(serviceAccountName) > 0:
                for param in data["parameters"]:
                    if "example" in param and param["example"].endswith("app-secret"):
                        secretName += param["example"] + '\n'
                    elif "value" in param and param["value"].endswith("app-secret"):
                        secretName += param["value"] + '\n'
                tdata['objects'][0]['secrets'] = [{"secretNames": secretName}]

        # currently only the rhpam-authoring-ha will have clustering section, any new template that supports clustering needs to be added in the var below.
        clusteringTemplates = ['rhpam71-authoring-ha.yaml']
        for template in clusteringTemplates:
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


def buildRow(columns):
    return "\n|" + " | ".join(map(possibly_fix_width, columns))


def getVolumePurpose(name):
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
def getVariableInfo(data, name, value):
    for d in data:
        if (d["name"] == name or name[1:] in d["name"] or d["name"][1:] in name):
            return str(d[value]).replace("|", "\\|")
    if (value == "value" and name in PARAMETER_VALUES.keys()):
        return PARAMETER_VALUES[name]
    else:
        return "--"


def createParameterTable(data):
    text = ""
    for param in data["parameters"]:
        if u"\u2019" in param["description"]:
            param["description"] = param["description"].replace(u"\u2019", "'")
        deploy = [d["spec"]["template"]["spec"]["containers"][0]["env"] for d in data["objects"] if
                  d["kind"] == "DeploymentConfig"]
        environment = [item for sublist in deploy for item in sublist]
        envVar = getVariableInfo(environment, param["name"], "name")
        value = param["value"] if param.get("value") else getVariableInfo(environment, param["name"], "value")
        req = param["required"] if "required" in param else "?"
        columns = [param["name"], envVar, str(param["description"]).replace("|", "\\|"), value, req]
        text += buildRow(columns)
    return text


def createObjectTable(data, tableKind):
    text = ""
    columns = []
    for obj in data["objects"]:
        if obj["kind"] == 'Service' and tableKind == 'Service':
            addDescription = True
            ports = obj["spec"]["ports"]
            text += "\n." + str(len(ports)) + "+| `" + obj["metadata"]["name"] + "`"
            for p in ports:
                columns = ["port", "name"]
                columns = [str(p[col]) if p.get(col) else "--" for col in columns]
                text += buildRow(columns)
                if addDescription:
                    text += "\n." + str(len(ports)) + "+| " + obj["metadata"]["annotations"]["description"]
                    addDescription = False
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
                    varValue = getVariableInfo(data['parameters'], varName, "value")
                    s2i = s2i.replace('${' + varName + '}', varValue)
                if "${" in tempS2i[1]:
                    varName = tempS2i[1][tempS2i[1].find("{") + 1:tempS2i[1].find("}")]
                    varValue = getVariableInfo(data['parameters'], varName, "value")
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
            text += buildRow(columns)
    return text


def createDeployConfigTable(data, table):
    text = ""
    deploymentConfig = (obj for obj in data["objects"] if obj["kind"] == "DeploymentConfig")
    for obj in deploymentConfig:
        columns = []
        deployment = obj["metadata"]["name"]
        spec = obj["spec"]
        template = spec["template"]["spec"]
        if (template.get(table) or spec.get(table)):
            if table == "triggers":
                columns = [deployment, spec["triggers"][0]["type"]]
            elif table == "replicas":
                columns = [deployment, str(spec["replicas"])]
            elif table == "serviceAccountName":
                columns = [deployment, template["serviceAccountName"]]
            elif table == "volumes":
                volumeMount = obj["spec"]["template"]["spec"]["containers"][0]["volumeMounts"][0]
                name = template["volumes"][0]["name"]
                readOnly = str(volumeMount["readOnly"]) if "readOnly" in volumeMount else "false"
                columns = [deployment, name, volumeMount["mountPath"], getVolumePurpose(name), readOnly]
            text += buildRow(columns)
    return text


def createContainerTable(data, table):
    text = ""
    deploymentConfig = (obj for obj in data["objects"] if obj["kind"] == "DeploymentConfig")
    for obj in deploymentConfig:
        columns = []
        deployment = obj["metadata"]["name"]
        container = obj["spec"]["template"]["spec"]["containers"][0]
        if table == "image":
            columns = [deployment, container["image"]]
            text += buildRow(columns)
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
        elif table == "livenessProbe":
            if 'livenessProbe' in container:
                if 'httpGet' in container["livenessProbe"]:
                    text += ("\n." + deployment + "\n----\n" \
                             + "".join(
                                "Http Get on http://localhost:" + str(container["readinessProbe"]["httpGet"]["port"])) \
                             + "".join(container["readinessProbe"]["httpGet"]["path"]) \
                             + "\n----\n")
                elif 'exec' in container["livenessProbe"]:
                    text += ("\n." + deployment + "\n----\n" \
                             + " ".join(container["readinessProbe"]["exec"]["command"]) \
                             + "\n----\n")

        elif table == "ports":
            text += "\n." + str(len(container["ports"])) + "+| `" + deployment + "`"
            ports = container["ports"]
            for p in ports:
                columns = ["name", "containerPort", "protocol"]
                columns = [str(p[col]) if p.get(col) else "--" for col in columns]
                text += buildRow(columns)
        elif table == "env":
            environment = container["env"]
            text += "\n." + str(len(environment)) + "+| `" + deployment + "`"
            for env in environment:
                columns = [env["name"], getVariableInfo(data["parameters"], env["name"], "description")]
                # TODO: handle valueFrom instead of value
                if "value" in env:
                    columns.append(env["value"])
                else:
                    columns.append("--")
                text += buildRow(columns)
    return text


def generate_readme(generate_rhdm, generate_rhpam):
    """Generates a README page for the template documentation."""
    if generate_rhdm:
        try:
            with open('docs/rhdm-7-openshift-image/README.adoc', 'w') as fh:
                fh.write(autogen_warning)
                # page header
                fh.write(open('./README_RHDM.adoc.in').read())
                for directory in sorted(template_dirs):
                    if not os.path.isdir(directory):
                        continue
                    elif "rhdm" in directory:
                        # section header
                        fh.write('\n== %s\n\n' % fullname.get(directory, directory))
                        # links
                        for template in [os.path.splitext(x)[0] for x in sorted(os.listdir(directory))]:
                            # XXX: Hack for 1.3 release, which excludes processserver
                            if template != "processserver-app-secret" and "image-stream" not in template:
                                fh.write("* link:%s.adoc[%s]\n" % (template, template))
                # release notes
                fh.write(open('./release-notes-rhdm.adoc.in').read())
        except IOError, e:
            print("Error while writing README_RHDM.adoc: " + str(e))
            pass

    if generate_rhpam:
        try:
            with open('docs/rhpam-7-openshift-image/README.adoc', 'w') as fh:
                fh.write(autogen_warning)
                # page header
                fh.write(open('./README_RHPAM.adoc.in').read())

                for directory in sorted(template_dirs):
                    if not os.path.isdir(directory):
                        continue
                    elif "rhpam" in directory:
                        # section header
                        fh.write('\n== %s\n\n' % fullname.get(directory, directory))
                        # links
                        for template in [os.path.splitext(x)[0] for x in sorted(os.listdir(directory))]:
                            # XXX: Hack for 1.3 release, which excludes processserver
                            if template != "processserver-app-secret" and "image-stream" not in template:
                                fh.write("* link:%s.adoc[%s]\n" % (template, template))
                # release notes
                fh.write(open('./release-notes-rhpam.adoc.in').read())
        except IOError, e:
            print("Error while writing README_RHPAM.adoc: " + str(e))
            pass


def pull_templates(rhdm_git_branch, rhpam_git_branch):
    print ('Pulling templates from {0}'.format(GIT_REPO_LIST))
    try:
        for dir in APPLICATION_DIRECTORIES:
            shutil.rmtree(dir, ignore_errors=True)

    except OSError as e:
        print("Error: %s - %s." % (e.filename, e.strerror))

    for repo in GIT_REPO_LIST:
        git_dir = repo.rsplit('/', 1)[-1].replace('.git', '')
        if 'rhdm' in git_dir:
            print('Using RHDM branch {0}'.format(rhdm_git_branch))
            clone_repository(repo, git_dir, bare=False, checkout_branch=rhdm_git_branch)
        elif 'rhpam' in git_dir:
            print('Using RHPAM branch {0}'.format(rhpam_git_branch))
            clone_repository(repo, git_dir, bare=False, checkout_branch=rhpam_git_branch)


# expects to be run from the root of the repository
if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='OpenShift Application Templates docs generator')
    parser.add_argument('--rhdm-git-branch', dest='rhdm_git_branch', default='rhdm71-dev', help='Branch to checkout')
    parser.add_argument('--rhpam-git-branch', dest='rhpam_git_branch', default='rhpam71-dev', help='Branch to checkout')
    parser.add_argument('--rhdm', dest='generate_rhdm', action='store_true', default=False,
                        help='If set, only rhdm template docs will be generated')
    parser.add_argument('--rhpam', dest='generate_rhpam', action='store_true', default=False,
                        help='If set, only rhpam template docs will be generated')
    parser.add_argument('--template', dest='template', help='Generate the docs for only one template')
    args = parser.parse_args()

    if not args.generate_rhdm and not args.generate_rhpam:
        GIT_REPO_LIST = [RHDM_GIT_REPO, RHPAM_GIT_REPO]
    elif args.generate_rhdm:
        GIT_REPO_LIST = [RHDM_GIT_REPO]
    elif args.generate_rhpam:
        GIT_REPO_LIST = [RHPAM_GIT_REPO]
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
        # pull all the templates from upstream
        pull_templates(args.rhdm_git_branch, args.rhpam_git_branch)
        generate_templates()
        generate_readme(args.generate_rhdm, args.generate_rhpam)
