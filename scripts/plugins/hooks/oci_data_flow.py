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

from typing import Optional
import oci
from hooks.oci_base import OCIBaseHook
from airflow.exceptions import AirflowException

"""
Get OCID by Name - Compartment ID, Application Name
"""

class OCIDataFlowHook(OCIBaseHook):
    """
    Interact with Oracle Data Flow.
    """
    def __init__(self,
                 compartment_ocid: str,
                 display_name: str,
                 oci_conn_id: Optional[str] = "oci_default",
                 oci_region: Optional[str] = None,
                 driver_shape: Optional[str] = None,
                 executor_shape: Optional[str] = None,
                 file_uri: Optional[str] = None,
                 language: Optional[str] = "English",
                 num_executors: Optional[int] = "1",
                 spark_version: Optional[str] = None,
                 *args,
                 **kwargs):
        super(OCIDataFlowHook, self).__init__(*args, **kwargs)
        self.compartment_id = compartment_ocid
        self.display_name = display_name
        self.oci_conn_id = oci_conn_id
        self.oci_region = oci_region
        self.driver_shape = driver_shape
        self.executor_shape = executor_shape
        self.file_uri = file_uri
        self.language = language
        self.num_executors = num_executors
        self.spark_version = spark_version
        self.oci_client = oci.data_flow.DataFlowClient

    def get_application_ocid(self, compartment_id, display_name):
        try:
            appdetails = self.oci_client.list_applications(compartment_id=compartment_id,
                                                           display_name=display_name).data
            if appdetails.display_name == display_name:
                return appdetails.id
            else:
                return None
        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])

    def create_application_details(self):
        try:
            application_details = oci.data_flow.models.CreateApplicationDetails(compartment_id=self.compartment_id,
                                                                                display_name=self.display_name,
                                                                                driver_shape=self.driver_shape,
                                                                                executor_shape=self.executor_shape,
                                                                                file_uri=self.file_uri,
                                                                                language=self.language,
                                                                                num_executors=self.num_executors,
                                                                                spark_version=self.spark_version,
                                                                                **kwargs)
            return application_details
        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])

    def create_run_details(self):
        try:
            run_details = oci.data_flow.models.CreateRunDetails(compartment_id=self.compartment_id,
                                                                application_id=self.get_application_ocid(self.display_name),
                                                                display_name=self.display_name,
                                                                **kwargs)
            return run_details
        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])

