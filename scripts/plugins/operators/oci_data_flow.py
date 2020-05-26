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

from airflow.models.baseoperator import BaseOperator
from airflow.utils.decorators import apply_defaults
from typing import Optional
import oci
from oci.data_flow.data_flow_client_composite_operations import DataFlowClientCompositeOperations
from hooks.oci_data_flow import OCIDataFlowHook
from hooks.oci_object_storage import OCIObjectStorageHook
from airflow.exceptions import AirflowException
"""
Interact with OCI Data Flow
"""


class OCIDataFlowRun(BaseOperator):
    """
    Create a Data Flow Run
    :param comprtment_ocid: Compartment OCID
    :param application_ocid: Data Flow Applicaation OCID
    :param display_name: Data Flow App Name
    :param oci_conn_id: Airflow Connection ID
    :param bucket_name: Application Bucket Name
    :param parameters: Parameters
    :param driver_shape: Spark Driver Shape
    :param executor_shape: Spark Executor Shape
    :param num_executors: Spark Executors
    :param logs_bucket_uri: OCI Logs Bucket
    :param defined_tags: Defined Tags
    :param freeform_tags: Freeform Tags
    :param check_interval: Check Interval
    :param timeout: Timeout
    """
    @apply_defaults
    def __init__(
            self,
            compartment_ocid: str,
            application_ocid,
            display_name,
            oci_conn_id: str,
            bucket_name: str,
            parameters: Optional = None,
            driver_shape: Optional = None,
            executor_shape: Optional = None,
            num_executors: Optional = None,
            logs_bucket_uri: Optional = None,
            defined_tags: Optional = None,
            freeform_tags: Optional = None,
            check_interval: Optional[int] = None,
            timeout: Optional[int] = None,
            *args,
            **kwargs
    ):
        super().__init__(*args, **kwargs)
        self.compartment_id = compartment_ocid
        self.application_id = application_ocid
        self.display_name = display_name
        self.oci_conn_id = oci_conn_id
        self.bucket_name = bucket_name
        self.parameters = parameters
        self.driver_shape = driver_shape
        self.executor_shape = executor_shape
        self.num_executors = num_executors
        self.logs_bucket_uri = logs_bucket_uri
        self.defined_tags = defined_tags
        self.freeform_tags = freeform_tags
        self.check_interval = check_interval
        self.timeout = timeout
        self._oci_hook = None

    def execute(self, context):
        self._oci_hook = OCIDataFlowHook(compartment_ocid=self.compartment_id, oci_conn_id=self.oci_conn_id)
        client = self._oci_hook.get_client(oci.data_flow.DataFlowClient)
        self.log.info("Validating OCI Config")
        self._oci_hook.validate_config()
        if not self.timeout:
            self.timeout = float('inf')
        if not self.check_interval:
            self.check_interval = 30
        if not self.executor_shape:
            self.executor_shape = 'VM.Standard2.1'
        if not self.num_executors:
            self.num_executors = 1
        if not self.driver_shape:
            self.driver_shape = self.executor_shape
        if not self.warehouse_bucket_uri:
            self.namespace = OCIObjectStorageHook().get_namespace(compartment_id=self.compartment_id)
            self.warehouse_bucket_uri = "oci://" + self.bucket_name + "@" + self.namespace + "/"
        self.application_id = self._oci_hook.get_application_ocid(compartment_id=self.compartment_id, display_name=self.display_name)
        run_details = {
            "application_id": self.application_id,
            "compartment_id": self.compartment_id,
            "display_name": self.display_name,
            "executor_shape": self.executor_shape,
            "num_executors": self.num_executors,
            "driver_shape": self.driver_shape,
            "warehouse_bucket_uri": self.warehouse_bucket_uri
        }
        dataflow_run = oci.data_flow.models.CreateRunDetails(application_id=run_details["application_id"],
                                                    compartment_id=run_details["compartment_id"],
                                                    display_name=run_details["display_name"],
                                                    executor_shape=run_details["executor_shape"],
                                                    num_executors=run_details["num_executors"],
                                                    driver_shape=run_details["driver_shape"],
                                                    warehouse_bucket_uri=run_details["warehouse_bucket_uri"]
                                                    )
        try:
            print("Submitting Data Flow Run")
            submit_run = DataFlowClientCompositeOperations(client)
            submit_run.create_run_and_wait_for_state(create_run_details=dataflow_run,
                                                     wait_for_states=["SUCCEEDED", "FAILED"],
                                                     waiter_kwargs={
                                                         "max_interval_seconds": self.check_interval,
                                                         "max_wait_seconds": self.timeout
                                                     })
        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])
