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
from oci.data_catalog.data_catalog_client import DataCatalogClient
from hooks.oci_data_catalog import OCIDataCatalogHook
from airflow.exceptions import AirflowException
import time
"""
Interact with OCI Data Catalog
"""


class OCIDataCatalogExecute(BaseOperator):
    """
    Create Data Catalog Job Execution
    :param compartment_ocid: Compartment OCID
    :param oci_conn_id: Airflow connection ID
    :param data_catalog_ocid: Data Catalog OCID
    :param retry_strategy: Retry Strategy
    """

    @apply_defaults
    def __init__(
            self,
            compartment_ocid: str,
            oci_conn_id: str,
            data_catalog_ocid: str,
            job_key: str,
            job_execution_details: object,
            retry_strategy: Optional[str] = None,
            *args,
            **kwargs
    ):
        super().__init__(*args, **kwargs)
        self.compartment_id = compartment_ocid
        self.oci_conn_id = oci_conn_id
        self.data_catalog_ocid = data_catalog_ocid
        self.job_key = job_key
        self.job_execution_details = job_execution_details
        self.retry_strategy = retry_strategy
        self._oci_hook = None

    def execute(self, context, **kwargs):
        self._oci_hook = OCIDataCatalogHook(compartment_ocid=self.compartment_id, oci_conn_id=self.oci_conn_id)
        client = self._oci_hook.get_client(oci.data_catalog.DataCatalogClient)
        self.log.info("Validating OCI Config")
        self._oci_hook.validate_config()

        try:
            print("Submitting Data Catalog Job Execution")
            submit_job = DataCatalogClient(client)
            submit_job.create_job_execution(catalog_id=self.data_catalog_ocid,
                                            job_key=self.job_key,
                                            create_job_execution_details=self.job_execution_details,
                                            **kwargs)
            check_job = DataCatalogClient(client)
            job_data = check_job.get_job(catalog_id=self.data_catalog_ocid,
                                                job_key=self.job_key).data
            while job_data.lifecycle_state is not "completed":
                time.sleep(15)
                job_data = check_job.get_job(catalog_id=self.data_catalog_ocid,
                                             job_key=self.job_key).data

        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])
