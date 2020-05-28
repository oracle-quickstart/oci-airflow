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
This module contains OCI Object Storage Hook.
"""
import gzip as gz
import io
from airflow.utils.helpers import chunks
from typing import Optional

import oci
from hooks.oci_base import OCIBaseHook
from airflow.exceptions import AirflowException

class OCIObjectStorageHook(OCIBaseHook):
    """
    Interact with OCI Object Storage
    :param bucket_name: Target bucket name
    :type bucket_name: str
    :param compartment_id: Target compartment OCID
    :type compartment_id: str
    :param oci_conn_id: Airflow connection ID
    :type oci_conn_id: str
    """
    def __init__(self,
                 compartment_id: str,
                 oci_conn_id: str,
                 bucket_name: str,
                 *args,
                 **kwargs):
        super(OCIObjectStorageHook, self).__init__(*args, **kwargs)
        self.bucket_name = bucket_name
        self.oci_conn_id = oci_conn_id
        self.compartment_id = compartment_id
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
            namespace_name = self.get_client(self.oci_client).get_namespace(compartment_id=self.compartment_id).data
            return namespace_name
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
            bucketsummary = self.get_client(self.oci_client).list_buckets(namespace_name=namespace_name,
                                                                          compartment_id=self.compartment_id)
            bucket_list = bucketsummary.data
            for bucket in bucket_list:
                if bucket.name == bucket_name:
                    return True
                else:
                    continue
            return False
        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])

    def check_for_object(self, bucket_name=None, namespace_name=None, object_name=None):
        """
        Check if Object exists in Bucket
        :param bucket_name: Target Bucket name
        :param namespace_name: Object Storage Namespace
        :param object_name: Name of Object in Bucket to check if exists
        :return: True if exists, False if not
        :rtype: bool
        """
        try:
            objectsummary = self.get_client(self.oci_client).list_objects(namespace_name=namespace_name,
                                                                          bucket_name=bucket_name)
            object_list = objectsummary.data
            print("Object list: {0}".format(object_list))
            if object_list.next_start_with is None:
                return False
            else:
                for object in object_list:
                    if object.name == object_name:
                        return True
                    else:
                        continue
                return False
        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])

    def copy_to_bucket(self, bucket_name=None, namespace_name=None, put_object_body=None, object_name=None,
                       **kwargs):
        """
        Copy Source Data to Bucket using put_object
        :param bucket_name:
        :type bucket_name: str
        :param namespace_name:
        :type namespace_name: str
        :param put_object_body: The object to upload to the object store
        :type put_object_body: stream
        :param object_name: Name of Object to be created in Bucket
        :type object_name: str
        :return:
        """
        try:
            self.get_client(self.oci_client).put_object(bucket_name=bucket_name, namespace_name=namespace_name,
                                                        put_object_body=put_object_body, object_name=object_name,
                                                        **kwargs)
        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])







