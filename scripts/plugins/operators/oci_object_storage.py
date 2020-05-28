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
This module contains OCI Object Storage Operator.
"""
from airflow.models.baseoperator import BaseOperator
from hooks.oci_object_storage import OCIObjectStorageHook
from airflow.utils.decorators import apply_defaults
from airflow.exceptions import AirflowException
from os import path
import oci


class MakeBucket(BaseOperator):
    """
    Create a Bucket
    """

    @apply_defaults
    def __init__(
        self,
        bucket_name: str,
        compartment_ocid: str,
        oci_conn_id: str,
        *args,
        **kwargs
    ) -> None:
        super().__init__(*args, **kwargs)
        self.bucket_name = bucket_name
        self.compartment_id = compartment_ocid
        self.oci_conn_id = oci_conn_id
        self._oci_hook = None
        self._oci_storage_hook = None

    def execute(self, context):
        self._oci_hook = OCIObjectStorageHook(compartment_id=self.compartment_id, bucket_name=self.bucket_name,
                                              oci_conn_id=self.oci_conn_id)
        client = self._oci_hook.get_client(oci.object_storage.ObjectStorageClient)
        self.log.info("Validating OCI Config")
        self._oci_hook.validate_config()
        namespace = self._oci_hook.get_namespace()
        details = oci.object_storage.models.CreateBucketDetails(
            compartment_id=self.compartment_id, name=self.bucket_name
        )
        self.log.info("Checking if Bucket {} exists".format(self.bucket_name))
        bucket_exists = self._oci_hook.check_for_bucket(namespace_name=namespace, bucket_name=self.bucket_name)
        if bucket_exists is True:
            self.log.info("Bucket {0} exists, skipping creation".format(self.bucket_name))
        else:
            self.log.info("Creating Bucket {0} in {1}".format(self.bucket_name, namespace))
            client.create_bucket(namespace_name=namespace, create_bucket_details=details)
            self.log.info("Create bucket complete")


class CopyFileToOCIObjectStorageOperator(BaseOperator):
    """
    Copy Local File to OCI Object Storage Operator
    """

    @apply_defaults
    def __init__(
            self,
            bucket_name: str,
            compartment_ocid: str,
            oci_conn_id: str,
            object_name: str,
            local_file_path: str,
            *args,
            **kwargs
    ) -> None:
        super().__init__(*args, **kwargs)
        self.bucket_name = bucket_name
        self.compartment_id = compartment_ocid
        self.oci_conn_id = oci_conn_id
        self.object_name = object_name
        self.local_file_path = local_file_path
        self._oci_hook = None
        self._oci_storage_hook = None

    def execute(self, context):
        self._oci_hook = OCIObjectStorageHook(compartment_id=self.compartment_id, bucket_name=self.bucket_name,
                                              oci_conn_id=self.oci_conn_id)
        client = self._oci_hook.get_client(oci.object_storage.ObjectStorageClient)
        self.log.info("Validating OCI Config")
        self._oci_hook.validate_config()
        namespace = self._oci_hook.get_namespace()
        details = oci.object_storage.models.CreateBucketDetails(
            compartment_id=self.compartment_id, name=self.bucket_name
        )
        self.log.info("Checking if Bucket {} exists".format(self.bucket_name))
        bucket_exists = self._oci_hook.check_for_bucket(namespace_name=namespace, bucket_name=self.bucket_name)
        if bucket_exists is True:
            self.log.info("Bucket {0} exists, skipping creation".format(self.bucket_name))
        else:
            self.log.info("Creating Bucket {0} in {1}".format(self.bucket_name, namespace))
            client.create_bucket(namespace_name=namespace, create_bucket_details=details)
            self.log.info("Create bucket complete")
        self.log.info("Checking if {0} exists in {1}".format(self.object_name, self.bucket_name))
        object_exists = self._oci_hook.check_for_object(namespace_name=namespace, bucket_name=self.bucket_name,
                                                        object_name=self.object_name)
        if object_exists is True:
            self.log.info("Object {0} exists already in {1}".format(self.object_name, self.bucket_name))
        else:
            self.log.info("Validating local file {0} exists".format(self.object_name))
            if path.exists(self.local_file_path) is True:
                self.local_file = self.local_file_path + self.object_name
                if path.exists(self.local_file) is True:
                    self.log.info("Copying {0} to {1}".format(self.local_file, self.bucket_name))
                    self.put_object_body = open(self.local_file, 'rb')
                    self._oci_hook.copy_to_bucket(bucket_name=self.bucket_name,
                                                  namespace_name=namespace,
                                                  object_name=self.object_name,
                                                  put_object_body=self.put_object_body)
                else:
                    self.log.error("Local file {0} does not exist".format(self.local_file))
            else:
                self.log.error("Local file path {0} does not exist".format(self.local_file_path))


class CopyToOCIObjectStorageOperator(BaseOperator):
    """
    Copy to OCI Object Storage Operator
    """

    @apply_defaults
    def __init__(
        self,
        bucket_name: str,
        compartment_ocid: str,
        oci_conn_id: str,
        object_name: str,
        put_object_body: str,
        *args,
        **kwargs
    ) -> None:
        super().__init__(*args, **kwargs)
        self.bucket_name = bucket_name
        self.compartment_id = compartment_ocid
        self.oci_conn_id = oci_conn_id
        self.object_name = object_name
        self.put_object_body = put_object_body
        self._oci_hook = None
        self._oci_storage_hook = None

    def execute(self, context):
        self._oci_hook = OCIObjectStorageHook(compartment_id=self.compartment_id, bucket_name=self.bucket_name,
                                              oci_conn_id=self.oci_conn_id)
        client = self._oci_hook.get_client(oci.object_storage.ObjectStorageClient)
        self.log.info("Validating OCI Config")
        self._oci_hook.validate_config()
        namespace = self._oci_hook.get_namespace()
        details = oci.object_storage.models.CreateBucketDetails(
            compartment_id=self.compartment_id, name=self.bucket_name
        )
        self.log.info("Checking if Bucket {} exists".format(self.bucket_name))
        bucket_exists = self._oci_hook.check_for_bucket(namespace_name=namespace, bucket_name=self.bucket_name)
        if bucket_exists is True:
            self.log.info("Bucket {0} exists, skipping creation".format(self.bucket_name))
        else:
            self.log.info("Creating Bucket {0} in {1}".format(self.bucket_name, namespace))
            client.create_bucket(namespace_name=namespace, create_bucket_details=details)
            self.log.info("Create bucket complete")
        self.log.info("Checking if {0} exists in {1}".format(self.object_name, self.bucket_name))
        object_exists = self._oci_hook.check_for_object(namespace_name=namespace, bucket_name=self.bucket_name,
                                                        object_name=self.object_name)
        if object_exists is True:
            self.log.info("Object {0} exists already in {1}".format(self.object_name, self.bucket_name))
        else:
            self.log.info("Copying {0} to {1}".format(self.object_name, self.bucket_name))
            self._oci_hook.copy_to_bucket(bucket_name=self.bucket_name, namespace_name=namespace,
                                          object_name=self.object_name, put_object_body=self.put_object_body)


class CopyFromOCIObjectStorage(BaseOperator):
    """
    Copy from OCI Object Storage
    """
    @apply_defaults
    def __init__(
        self,
        bucket_name: str,
        compartment_id: str,
        oci_conn_id: str,
        object_name: str,
        *args,
        **kwargs
    ) -> None:
        super().__init__(*args, **kwargs)
        self.bucket_name = bucket_name
        self.compartment_id = compartment_id
        self.oci_conn_id = oci_conn_id
        self.object_name = object_name
        self._oci_hook = None
        self._oci_storage_hook = None

    def execute(self, context):
        self._oci_hook = OCIObjectStorageHook(compartment_id=self.compartment_id, bucket_name=self.bucket_name,
                                              oci_conn_id=self.oci_conn_id)
        client = self._oci_hook.get_client(oci.object_storage.ObjectStorageClient)
        self.log.info("Validating OCI Config")
        self._oci_hook.validate_config()
        namespace = self._oci_hook.get_namespace()
        self.log.info("Checking if {0} exists in {1}".format(self.object_name, self.bucket_name))
        object_exists = self._oci_hook.check_for_object(namespace_name=namespace, bucket_name=self.bucket_name,
                                                        object_name=self.object_name)
        if object_exists is True:
            self.log.info("Reading {0} from {1}".format(self.object_name, self.bucket_name))
            return client.get_object(namespace_name=namespace, object_name=self.object_name,
                                     bucket_name=self.bucket_name)
        else:
            raise AirflowException("{0} does not exist in {1}".format(self.object_name, self.bucket_name))

