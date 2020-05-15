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

import oci
from hooks.oci_base import OCIBaseHook
from airflow.exceptions import AirflowException


class OCIDataFlowHook(OCIBaseHook):
    """
    Interact with Oracle Data Flow.
    """
    def __init__(self,
                 compartment_id: str,
                 oci_conn_id: str,
                 *args,
                 **kwargs):
        super(OCIDataFlowHook, self).__init__(*args, **kwargs)
        self.compartment_id = compartment_id
        self.oci_conn_id = oci_conn_id
        self.oci_client = oci.data_flow.DataFlowClient

    def build_application_details(self, display_name, driver_shape, executor_shape, file_uri, language,
                                  num_executors, spark_version, **kwargs):
        try:
            application_details = oci.data_flow.models.CreateApplicationDetails(compartment_id=self.compartment_id,
                                                                                display_name=display_name,
                                                                                driver_shape=driver_shape,
                                                                                executor_shape=executor_shape,
                                                                                file_uri=file_uri,
                                                                                language=language,
                                                                                num_executors=num_executors,
                                                                                spark_version=spark_version,
                                                                                **kwargs)
            return application_details
        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])
