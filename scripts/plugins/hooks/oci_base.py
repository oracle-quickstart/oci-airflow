#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
"""
This module contains Base Oracle Cloud Infrastructure (OCI) Hook.
"""
from os import path
from typing import Optional
import oci
from airflow.exceptions import AirflowException
from airflow.hooks.base_hook import BaseHook


class OCIBaseHook(BaseHook):
    """
    Interact with OCI
    This class is a thin wrapper around the OCI Python SDK

    :param oci_conn_id: The OCI connection profile used for Airflow connection.
    :type oci_conn_id: str
    :param config: OCI API Access Configuration - usually read from Airflow but can be provided.
    :type config: dict
    :param verify: Whether or not to verify SSL certificates.
    :type verify: str or bool

    How to Set OCI configuration
    For detail on the contents of the default config file, see
    https://docs.cloud.oracle.com/en-us/iaas/Content/API/Concepts/sdkconfig.htm
    If you don't want to use a file, populate values as detailed here
    https://oracle-cloud-infrastructure-python-sdk.readthedocs.io/en/latest/configuration.html
    Fallback to Instance Principals if not using config files or passed parameters
    """

    def __init__(self,
                 oci_conn_id: Optional[str] = "oci_default",
                 verify: Optional[bool] = None
    ):
       super(OCIBaseHook, self).__init__(oci_conn_id)
       self.oci_conn_id = oci_conn_id
       self.config = None
       self.client_kwargs = None
       self.signer = None
       self.verify = verify

    def get_config(self):
        try:
            connection_object = self.get_connection(self.oci_conn_id)
            extra_config = connection_object.extra_dejson
            if extra_config.get("extra__oci__tenancy"):
                self.config = {
                    "log_requests": False,
                    "additional_user_agent": '',
                    "pass_phrase": None,
                    "user": connection_object.login,
                    "fingerprint": extra_config["extra__oci__fingerprint"],
                    "key_file": extra_config["extra__oci__key_file"],
                    "tenancy": extra_config["extra__oci__tenancy"],
                    "region": extra_config["extra__oci__region"]
                }
                self.client_kwargs = dict()
            elif "config_path" in extra_config:
                if path.exists(extra_config["config_path"]) is True:
                    self.config = oci.config.from_file(extra_config["config_path"])
                    self.client_kwargs = dict()
                else:
                    raise AirflowException('Config Path %s not found' % extra_config["config_path"])
            else:
                self.log.info("Failed to find valid oci config in Airflow, falling back to Instance Principals")
                self.signer = oci.auth.signers.InstancePrincipalsSecurityTokenSigner()
                self.client_kwargs = dict(signer=self.signer)
                self.config = {
                    "tenancy": self.signer.tenancy_id,
                    "region": self.signer.region,
                }
        except AirflowException as e:
            self.log.error("All attempts to get valid configuration failed")
            self.log.error(str(e))
            raise e
        return self.config, self.client_kwargs

    def validate_config(self):
        from oci.config import validate_config
        try:
            validate_config(self.config, **self.client_kwargs)
            self.identity = oci.identity.IdentityClient(self.config, **self.client_kwargs)
            if "user" in self.config:
                self.user = self.identity.get_user(self.config["user"]).data
        except AirflowException:
            self.log.warning("Configuration Validation Failed")

    def get_client(self, client_class):
        client, client_kwargs = self.get_config()
        return client_class(client, **client_kwargs)



