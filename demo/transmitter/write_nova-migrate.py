# Copyright 2017 NEC Corporation
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

import collectd
import socket
import sys
from novaclient import client


class OSCliNova:

    def __init__(self):
        self.hostname = socket.getfqdn()
        self.novaclient = None

    def configure(self, conf):
        for node in conf.children:
            if node.key == "Username":
                username = node.values[0]
            elif node.key == "Password":
                password = node.values[0]
            elif node.key == "TenantName":
                tenant_name = node.values[0]
            elif node.key == "AuthURL":
                auth_url = node.values[0]
        self.novaclient = client.Client(version='1.1',
                                        username=username,
                                        password=password,
                                        project_id=tenant_name,
                                        auth_url=auth_url,
                                        endpoint_type='internalURL',
                                        connection_pool=True)
        # print >> sys.stderr, (username, password, tenant_name, auth_url)

    def notify(self, vl, data=None):
        if vl.severity < 4:
            hypervisors = self.novaclient.hypervisors.search(
                              self.hostname, servers=True)
            for hyper in hypervisors:
                if hasattr(hyper, 'servers'):
                    for server in hyper.servers:
                        self.novaclient.servers.live_migrate(server['uuid'],
                                                             None, True, False)


cli = OSCliNova()

collectd.register_config(cli.configure)
collectd.register_notification(cli.notify)
