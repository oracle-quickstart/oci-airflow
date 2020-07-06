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
        self._oci_hook = None

    def poke(self, context):
        raise Exception("Class did not implement poke method")

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
        namespace_name = self.get_oci_hook().get_namespace(compartment_id=self.compartment_id)
        return self.get_oci_hook().check_for_object(bucket_name=self.bucket_name, namespace_name=namespace_name,
                                                    object_name=self.object_name)


class OCIObjectStoragePrefixSensor(BaseOCIObjectStorageSensor):
    """
    Prefix sensor for OCI Object Storage
    """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def poke(self, context):
        self.log.info('Poking for prefix %s in bucket %s', self.prefix, self.bucket_name)
        try:
            hook = self.get_oci_hook()
            namespace_name = hook.get_namespace(compartment_id=self.compartment_id)
            object_store_client = hook.get_client(hook.oci_client)
            base_arguments = dict(
                namespace_name=namespace_name,
                bucket_name=self.bucket_name,
                prefix=self.prefix,
                fields="size",
            )
            objectsummary = object_store_client.list_objects(**base_arguments)

            # Build a list of matching files.
            file_names = []
            total_files = 0
            total_size = 0
            while True:
                object_list = objectsummary.data
                for object in object_list.objects:
                    file_names.append(object.name)
                    total_files += 1
                    total_size += object.size
                if object_list.next_start_with is None:
                    break
                base_arguments["next_start_with"] = object_list.next_start_with
                object_store_client.list_object(**base_arguments)

            # If we matched anything, push the list and return true.
            if len(file_names) > 0:
                context['task_instance'].xcom_push('oci_prefix_file_names', file_names)
                context['task_instance'].xcom_push('oci_prefix_total_files', total_files)
                context['task_instance'].xcom_push('oci_prefix_total_size', total_size)
                return True
            return False

        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])

