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
from typing import Optional
from hooks.oci_base import OCIBaseHook
from airflow.exceptions import AirflowException


class OCIObjectStorageHook(OCIBaseHook):
    """
    Interact with OCI Object Storage

    :param compartment_id: Target compartment OCID
    :type compartment_id: str
    :param bucket_name: Target bucket name
    :type bucket_name: str
    :param namespace_name: Namespace name
    :type namespace_name: str
    :param oci_conn_id: Airflow connection ID
    :type oci_conn_id: str
    :param args: Additional arguments
    :param kwargs: Additional arguments
    """
    def __init__(self,
                 compartment_id: str,
                 bucket_name: Optional[str] = None,
                 namespace_name: Optional[str] = None,
                 oci_conn_id: Optional[str] = "oci_default",
                 *args,
                 **kwargs):
        super(OCIObjectStorageHook, self).__init__(*args, **kwargs)
        self.bucket_name = bucket_name
        self.oci_conn_id = oci_conn_id
        self.compartment_id = compartment_id
        self.namespace_name = namespace_name
        self.oci_client = oci.object_storage.ObjectStorageClient

    def get_namespace(self, compartment_id=None):
        """
        Get OCI Object Storage Namespace using config
        :param compartment_id: Compartment OCID
        :type compartment_id: str
        :return: Object Storage Namespace Name
        :rtype: str
        """
        try:
            self.namespace_name = self.get_client(self.oci_client).get_namespace(compartment_id=self.compartment_id).data
            return self.namespace_name
        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])


    def check_for_bucket(self, bucket_name=None, namespace_name=None):
        """
        Check if bucket_name exists
        :param bucket_name: Target bucket name
        :param namespace_name: Object Storage Namespace
        :return: True if exists, False if not
        :rtype: bool
        """
        try:
            bucketsummary = self.get_client(self.oci_client).list_buckets(namespace_name=self.namespace_name,
                                                                          compartment_id=self.compartment_id)
            bucket_list = bucketsummary.data
            for bucket in bucket_list:
                if bucket.name == self.bucket_name:
                    return True
                else:
                    continue
            return False
        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])

    def check_for_object(self, object_name, bucket_name=None, namespace_name=None, **kwargs):
        """
        Check if Object exists in Bucket
        :param bucket_name: Target Bucket name
        :param namespace_name: Object Storage Namespace
        :param object_name: Name of Object in Bucket to check if exists
        :return: True if exists, False if not
        :rtype: bool
        """
        if bucket_name is None:
            bucket_name = self.bucket_name
        if namespace_name is None:
            namespace_name = self.namespace_name
        try:
            # TODO: You might only need to check the first returned object.
            next_start_with = None
            while True:
                objectsummary = self.get_client(self.oci_client).list_objects(namespace_name=namespace_name,
                                                                              bucket_name=bucket_name,
                                                                              prefix=object_name,
                                                                              start_after=next_start_with,
                                                                              **kwargs)
                object_list = objectsummary.data
                for object in object_list.objects:
                    if object.name == object_name:
                        return True
                if object_list.next_start_with is None:
                    return False
                next_start_with = object_list.next_start_with
        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])

    def copy_to_bucket(self, bucket_name=None, namespace_name=None, put_object_body=None, object_name=None,
                       **kwargs):
        """
        Copy source data to bucket using put_object
        :param bucket_name: Target bucket
        :type bucket_name: str
        :param namespace_name: Namespace name
        :type namespace_name: str
        :param put_object_body: The object to upload to the object store
        :type put_object_body: stream
        :param object_name: Name of object to be created in bucket
        :type object_name: str
        :return: Response object with data type None
        """
        try:
            self.get_client(self.oci_client).put_object(bucket_name=self.bucket_name, namespace_name=self.namespace_name,
                                                        put_object_body=put_object_body, object_name=object_name,
                                                        **kwargs)
        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])

    def read_from_bucket(self, bucket_name=None, namespace_name=None, object_name=None, **kwargs):
        """
        Read object from bucket and return contents
        :param bucket_name: Target bucket
        :type bucket_name: str
        :param namespace_name: Namespace name
        :type namespace_name: str
        :param put_object_body: The object to upload to the object store
        :type put_object_body: stream
        :param object_name: Name of object to be created in bucket
        :type object_name: str
        :param kwargs:  additional arguments
        :return: Response object with data type stream
        """
        try:
            object_data = self.get_client(self.oci_client).get_object(bucket_name=self.bucket_name,
                                                                      namespace_name=self.namespace_name,
                                                                      object_name=object_name, **kwargs).data
            return object_data
        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])

