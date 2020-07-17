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

class BaseOCIObjectStorageSensor(BaseSensorOperator):
    template_fields = ('prefix', 'object_name', 'bucket_name')

    @apply_defaults
    def __init__(self,
                 compartment_ocid = None,
                 bucket_name = None,
                 object_name = None,
                 prefix = None,
                 namespace_name = None,
                 oci_conn_id = 'oci_default',
                 verify = None,
                 *args,
                 **kwargs):
        super().__init__(*args, **kwargs)
        if type(self).__name__ == "OCIObjectStorageSensor":
            if object_name is None:
                raise AirflowException('Please provide object_name')
            self.object_name = object_name
            self.prefix = None
        elif type(self).__name__ == "OCIObjectStoragePrefixSensor":
            if prefix is None:
                raise AirflowException('Please provide prefix')
            self.object_name = None
            self.prefix = prefix
        if bucket_name is None:
            raise AirflowException('Please provide bucket_name')
        self.compartment_id = compartment_ocid
        self.bucket_name = bucket_name
        self.oci_conn_id = oci_conn_id
        self.verify = verify
        self.namespace_name = namespace_name
        self._oci_hook = None

    def poke(self, context):
        raise Exception("Class did not implement poke method")

    def list_objects(self, file, prefix_match=False):
        hook = self.get_oci_hook()
        if not self.namespace_name:
            self.namespace_name = hook.get_namespace(compartment_id=self.compartment_id)
        object_store_client = hook.get_client(hook.oci_client)
        base_arguments = dict(
            bucket_name=self.bucket_name,
            fields="size",
            limit=100,
            namespace_name=self.namespace_name,
            prefix=file,
        )
        objectsummary = object_store_client.list_objects(**base_arguments)

        # For exact match we only consider the first match.
        if prefix_match == False:
            first_match = objectsummary.data.objects[0]
            if first_match.name == file:
                return 1, first_match.size
            return 0, 0

        # Prefix mode: Build a list of matching files.
        total_files = 0
        total_size = 0
        while True:
            object_list = objectsummary.data
            for object in object_list.objects:
                total_files += 1
                total_size += object.size
            if object_list.next_start_with is None:
                break
            base_arguments["next_start_with"] = object_list.next_start_with
            object_store_client.list_object(**base_arguments)
        return total_files, total_size

    def get_oci_hook(self):
        """
        Create and return OCI Hook
        :return:
        """
        if not self._oci_hook:
            self._oci_hook = OCIObjectStorageHook(bucket_name=self.bucket_name, compartment_id=self.compartment_id,
                                                  oci_conn_id=self.oci_conn_id, verify=self.verify)
        return self._oci_hook


class OCIObjectStorageSensor(BaseOCIObjectStorageSensor):
    """
    Sensor to interact with OCI Object Storage
    """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def poke(self, context):
        self.log.info('Poking for object %s in bucket %s', self.object_name, self.bucket_name)
        try:
            total_files, total_size = self.list_objects(self.prefix, prefix_match=False)
            if total_files > 0:
                self.log.info('Found object of size %d', total_size)
                context['task_instance'].xcom_push('oci_storage_sensor_size', total_size)
                return True
            self.log.info('Object not found')
            return False

        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])


class OCIObjectStoragePrefixSensor(BaseOCIObjectStorageSensor):
    """
    Prefix sensor for OCI Object Storage
    """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def poke(self, context):
        self.log.info('Poking for prefix [%s] in bucket %s', self.prefix, self.bucket_name)
        try:
            total_files, total_size = self.list_objects(self.prefix, prefix_match=True)

            # If we matched anything, record file count, total size and return true.
            if total_files > 0:
                self.log.info('Found %d objects with total size %d', total_files, total_size)
                context['task_instance'].xcom_push('oci_prefix_total_files', total_files)
                context['task_instance'].xcom_push('oci_prefix_total_size', total_size)
                return True
            self.log.info('No matching objects')
            return False

        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])

