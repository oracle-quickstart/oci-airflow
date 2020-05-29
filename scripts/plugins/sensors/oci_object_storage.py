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
# specific language
# governing permissions and limitations
# under the License.

from airflow.sensors.base_sensor_operator import BaseSensorOperator
from airflow.utils.decorators import apply_defaults
from airflow.exceptions import AirflowException
from hooks.oci_object_storage import OCIObjectStorageHook

class OCIObjectStorageSensor(BaseSensorOperator):
    """
    Sensor to interact with OCI Object Storage
    """

    @apply_defaults
    def __init__(self,
                 compartment_ocid = None,
                 bucket_name = None,
                 object_name = None,
                 oci_conn_id = 'oci_default',
                 verify = None,
                 *args,
                 **kwargs):
        super().__init__(*args, **kwargs)
        if object_name is None:
            raise AirflowException('Please provide object_name')
        elif bucket_name is None:
            raise AirflowException('Please provide bucket_name')
        elif object_name is None:
            raise AirflowException('Please provide object_name')
        else:
            self.compartment_id = compartment_ocid,
            self.bucket_name = bucket_name,
            self.object_name = object_name,
            self.oci_conn_id = oci_conn_id,
            self.verify = verify
            self._oci_hook = None

    def poke(self):
        self.log.info('Poking for object %s in bucket %s', self.object_name, self.bucket_name)
        namespace_name = self.get_oci_hook().get_namespace(compartment_id=self.compartment_id)
        return self.get_oci_hook().check_for_object(bucket_name=self.bucket_name, namespace_name=namespace_name,
                                                    object_name=self.object_name)

    def get_oci_hook(self):
        """
        Create and return OCI Hook
        :return:
        """
        if not self._oci_hook:
            self._oci_hook = OCIObjectStorageHook(bucket_name=self.bucket_name, compartment_id=self.compartment_id,
                                                  oci_conn_id=self.oci_conn_id, verify=self.verify)
            return self._oci_hook
