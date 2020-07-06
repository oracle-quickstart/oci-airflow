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
    template_fields = ('display_name',)

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
            display_name: str,
            oci_conn_id: str,
            bucket_name: Optional[str] = None,
            application_ocid: Optional = None,
            parameters: Optional = None,
            driver_shape: Optional = None,
            executor_shape: Optional = None,
            num_executors: Optional = None,
            logs_bucket_uri: Optional = None,
            defined_tags: Optional = None,
            freeform_tags: Optional = None,
            warehouse_bucket_uri: Optional = None,
            check_interval: Optional[int] = None,
            timeout: Optional[int] = None,
            runtime_callback: Optional = None,
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
        self.warehouse_bucket_uri = warehouse_bucket_uri
        self.check_interval = check_interval
        self.timeout = timeout
        self.runtime_callback = runtime_callback
        self._oci_hook = None

    def execute(self, context):
        self._oci_hook = OCIDataFlowHook(compartment_ocid=self.compartment_id, oci_conn_id=self.oci_conn_id, display_name=self.display_name)
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
            self.namespace = OCIObjectStorageHook(compartment_id=self.compartment_id, oci_conn_id=self.oci_conn_id, bucket_name=self.bucket_name).get_namespace()
            self.warehouse_bucket_uri = "oci://" + str(self.bucket_name) + "@" + str(self.namespace) + "/"
        if not self.application_id: 
            self.application_id = OCIDataFlowHook(compartment_ocid=self.compartment_id, oci_conn_id=self.oci_conn_id, display_name=self.display_name).get_application_ocid()
        run_details = {
            "application_id": self.application_id,
            "compartment_id": self.compartment_id,
            "display_name": self.display_name,
            "executor_shape": self.executor_shape,
            "num_executors": self.num_executors,
            "driver_shape": self.driver_shape,
            "warehouse_bucket_uri": self.warehouse_bucket_uri,
            "logs_bucket_uri": self.logs_bucket_uri,
            "parameters": self.parameters,
        }
        if self.runtime_callback is not None:
            callback_settings = self.runtime_callback(context)
            run_details = {**run_details, **callback_settings}
        dataflow_run = oci.data_flow.models.CreateRunDetails(**run_details)
        try:
            submit_run = DataFlowClientCompositeOperations(client)
            response = submit_run.create_run_and_wait_for_state(create_run_details=dataflow_run,
                                                     wait_for_states=["CANCELED", "SUCCEEDED", "FAILED"],
                                                     waiter_kwargs={
                                                         "max_interval_seconds": self.check_interval,
                                                         "max_wait_seconds": self.timeout
                                                         })
            if response.data.lifecycle_state != "SUCCEEDED":
                self.log.error(response.data.lifecycle_details)
                raise AirflowException(response.data.lifecycle_details)
        except oci.exceptions.CompositeOperationError as e:
            self.log.error(str(e.cause))
            raise e


class OCIDataFlowCreateApplication(BaseOperator):
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
            display_name: str,
            oci_conn_id: str,
            bucket_name: str,
            object_name: str,
            language: str,
            file_uri: Optional[str] = None,
            parameters: Optional = None,
            driver_shape: Optional = None,
            executor_shape: Optional = None,
            num_executors: Optional = None,
            logs_bucket_uri: Optional = None,
            spark_version: Optional = None,
            check_interval: Optional[int] = None,
            timeout: Optional[int] = None,
            *args,
            **kwargs
    ):
        super().__init__(*args, **kwargs)
        self.compartment_id = compartment_ocid
        self.display_name = display_name
        self.oci_conn_id = oci_conn_id
        self.bucket_name = bucket_name
        self.object_name = object_name
        self.language = language
        self.file_uri = file_uri
        self.parameters = parameters
        self.driver_shape = driver_shape
        self.executor_shape = executor_shape
        self.num_executors = num_executors
        self.logs_bucket_uri = logs_bucket_uri
        self.spark_version = spark_version
        self.check_interval = check_interval
        self.timeout = timeout
        self._oci_hook = None

    def execute(self, context):
        self._oci_hook = OCIDataFlowHook(compartment_ocid=self.compartment_id, oci_conn_id=self.oci_conn_id, display_name=self.display_name)
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
        if not self.file_uri:
            self.namespace = OCIObjectStorageHook(compartment_id=self.compartment_id, oci_conn_id=self.oci_conn_id, bucket_name=self.bucket_name).get_namespace()
            self.file_uri = "oci://" + str(self.bucket_name) + "@" + str(self.namespace) + "/" + str(self.object_name)
            self.log.info("File URI: {0}".format(self.file_uri))
        if not self.language:
            self.log.error("Application Language must be set")
        if not self.spark_version:
            self.spark_version = '2.4.4'
        app_details = {
            "compartment_id": self.compartment_id,
            "display_name": self.display_name,
            "driver_shape": self.driver_shape,
            "executor_shape": self.executor_shape,
            "file_uri": self.file_uri,
            "language": self.language,
            "num_executors": self.num_executors,
            "spark_version": self.spark_version
        }
        dataflow_create = \
            oci.data_flow.models.CreateApplicationDetails(compartment_id=app_details["compartment_id"],
                                                          display_name=app_details["display_name"],
                                                          driver_shape=app_details["driver_shape"],
                                                          executor_shape=app_details["executor_shape"],
                                                          file_uri=app_details["file_uri"],
                                                          language=app_details["language"],
                                                          num_executors=app_details["num_executors"],
                                                          spark_version=app_details["spark_version"]
                                                          )
        try:
            print("Checking if Application {0} exists".format(self.display_name))
            appcheck = self._oci_hook.check_for_application_by_name()
            if appcheck is True:
                self.log.error("Application {0} already exists".format(self.display_name))
            else: 
                print("Creating DataFlow Application {0}".format(self.display_name))
                create_app = DataFlowClientCompositeOperations(client)
                create_app.create_application_and_wait_for_state(create_application_details=dataflow_create,
                                                                 wait_for_states=["ACTIVE"],
                                                                 waiter_kwargs={
                                                                     "max_interval_seconds": self.check_interval,
                                                                     "max_wait_seconds": self.timeout
                                                                 })
        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])
