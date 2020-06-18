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


class OCIDataCatalogHook(OCIBaseHook):
    """
    Interact with Oracle Data Catalog.
    """
    def __init__(self,
                 compartment_ocid: str,
                 data_catalog_ocid: Optional[str] = None,
                 display_name: Optional[str] = None,
                 oci_conn_id: Optional[str] = "oci_default",
                 oci_region: Optional[str] = None,
                 *args,
                 **kwargs):
        super(OCIDataCatalogHook, self).__init__(*args, **kwargs)
        self.compartment_id = compartment_ocid
        self.data_catalog_ocid = data_catalog_ocid
        self.display_name = display_name
        self.job_key = None
        self.oci_conn_id = oci_conn_id
        self.oci_region = oci_region
        self.oci_client = oci.data_catalog.DataCatalogClient

    def get_catalog_ocid(self, **kwargs):
        """
        Get Data Catalog OCID by catalog_name
        :param compartment_id:
        :param catalog_name:
        :return:
        """
        try:
            catalogdetails = self.get_client(self.oci_client).list_catalogs(compartment_id=self.compartment_id,
                                                                            **kwargs).data
            for catalog in catalogdetails:
                if catalog.display_name == self.display_name:
                    self.data_catalog_ocid = catalog.id
                    return catalog.id
                else:
                    continue
            return None
        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])

    def get_job_key(self, **kwargs):
        """
        Get Job Key by display_name
        :param kwargs:
        :return:
        """
        try:
            joblist = self.get_client(self.oci_client).list_jobs(compartment_id=self.compartment_id,
                                                                 display_name=self.display_name,
                                                                 **kwargs).data
            for job in joblist:
                if job.display_name == self.display_name:
                    self.job_key = job.key
                    return job.key
                else:
                    continue
            return None
        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])
