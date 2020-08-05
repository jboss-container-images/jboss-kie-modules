#!/usr/bin/python3

import os
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler


class MyHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        # do not change paths
        if self.path == '/apis/apps.openshift.io/v1/namespaces/testNamespace/deploymentconfigs?labelSelector=services.server.kie.org%2Fkie-server-id%3Drhpam-kieserevr-scale-up':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            test = os.path.join(sys.path[0], "responses/kieserver-dc.json")
            response = open(test, "r").read()
            self.wfile.write(response.encode(encoding='utf_8'))

        # do not change paths
        if self.path == '/apis/apps.openshift.io/v1/namespaces/testNamespace/deploymentconfigs?labelSelector=services.server.kie.org%2Fkie-server-id%3Drhpam-kieserevr-scale-down':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            test = os.path.join(sys.path[0], "responses/kieserver-dc-0-replicas.json")
            response = open(test, "r").read()
            self.wfile.write(response.encode(encoding='utf_8'))

        if self.path == '/apis/apps.openshift.io/v1/namespaces/testNamespace/deploymentconfigs/rhpam-central-console':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            test = os.path.join(sys.path[0], "responses/bc-dc.json")
            response = open(test, "r").read()
            self.wfile.write(response.encode(encoding='utf_8'))

        if self.path == '/halt':
            print("Halting server")
            self.send_response(200)
            self.end_headers()
            sys.exit()

        if self.path == '/kubernetes.default.svc':
            print("kubernetes.default.svc")
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            test = os.path.join(sys.path[0], "responses/kubernetes.defaul.svc.json")
            response = open(test, "r").read()
            self.wfile.write(response.encode(encoding='utf_8'))

    # for patch method, only return 200 for any path
    def do_PATCH(self):
        self.send_response(200)

    # for put method, only return 200 for any path
    def do_PUT(self):
        self.send_response(200)

    # for put method, only return 200 for any path
    def do_DELETE(self):
        self.send_response(200)


httpd = HTTPServer(("localhost", 8080), MyHandler)
httpd.serve_forever()

