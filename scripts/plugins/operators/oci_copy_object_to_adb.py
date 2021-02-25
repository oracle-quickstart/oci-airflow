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
import pandas as pd
from typing import Optional
from hooks.oci_adb import OCIDBHook
from hooks.oci_object_storage import OCIObjectStorageHook
from airflow.models.baseoperator import BaseOperator
from airflow.utils.decorators import apply_defaults
from airflow.exceptions import AirflowException


class OCIDBCopyFromObject(BaseOperator):
    """
    Copy data from a file in Object Storage into OCI ADB/ADW
    :param compartment_id: Target compartment OCID
    :type compartment_id: str
    :param tns_admin_root: The wallet root directory.  The wallet will be loaded from $TNS_ADMIN/sqlnet.ora.
    If you do not set tns_admin_root, it is assumed to be in your environment.
    :type tns_admin_root: str
    :param database_ocid:  Database ID
    :type database_ocid: str
    :param db_workload: DB Workload type, valid options are DW or OLTP
    :type str:
    :param db_name: Databse Name (Not display)
    :type db_name: str
    :param debug: Whether to display debug output
    :type debug: bool
    :param dsn: DSN (TNS Name) for connection
    :type dsn: str
    :param oci_conn_id: Airflow connection ID
    :type oci_conn_id: str
    :param oci_region: Target OCI Region
    :type oci_region: str
    :param password: Database password for user_id
    :type password: str
    :param user_id: User ID for Database login
    :type user_id: str
    :param wallet_location: Filesystem location for wallet files
    :param wallet_location: str
    """

    @apply_defaults
    def __init__(self,
                 compartment_ocid: str,
                 bucket_name: str,
                 object_name: str,
                 tns_admin_root: Optional[str] = None,
                 database_ocid: Optional[str] = None,
                 db_workload: Optional[str] = None,
                 db_name: Optional[str] = None,
                 debug: Optional[bool] = False,
                 dsn: Optional[str] = None,
                 oci_conn_id: Optional[str] = "oci_default",
                 oci_region: Optional[str] = None,
                 password: Optional[str] = None,
                 user_id: Optional[str] = None,
                 wallet_location: Optional[str] = None,
                 *args,
                 **kwargs):
        super(OCIDBCopyFromObject, self).__init__(*args, **kwargs)
        self.compartment_id = compartment_ocid
        self.bucket_name = bucket_name
        self.object_name = object_name
        self.tns_admin_root = tns_admin_root
        self.database_id = database_ocid
        self.db_workload = db_workload
        self.db_name = db_name
        self.debug = debug
        self.dsn = dsn
        self.oci_conn_id = oci_conn_id
        self.oci_region = oci_region
        self.password = password
        self.user_id = user_id
        self.wallet_location = wallet_location
        self._oci_hook = None
        self._oci_storage_hook = None
        self.oci_client = oci.database.DatabaseClient

    def execute(self, context, **kwargs):
        try:
            self._oci_hook = OCIDBHook(compartment_ocid=self.compartment_id, db_name=self.db_name,
                                       db_workload=self.db_workload, tns_admin_root=self.tns_admin_root,
                                       wallet_location=self.wallet_location)
            self._oci_storage_hook = OCIObjectStorageHook(compartment_id=self.compartment_id,
                                                          bucket_name=self.bucket_name)
            self.log.info("Relocalizing sqlnet.ora")
            self._oci_hook.relocalize_sqlnet()
            self.log.info("Sqlnet.ora relocalized to {0}".format(self.tns_admin_root))
            self.log.info("Establishing DB Connection")
            with self._oci_hook.connect_sqlalchemy(dsn=self.dsn, user=self.user_id, password=self.password) as conn:
                namespace = self._oci_storage_hook.get_namespace(compartment_id=self.compartment_id)
                object_contents = self._oci_storage_hook.read_from_bucket(bucket_name=self.bucket_name,
                                                                          namespace_name=namespace,
                                                                          object_name=self.object_name)
                dff = pd.DataFrameFactory(conn)
                dff.write(object_contents, name=self.object_name, if_exists='replace')
        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])

