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
import os
import re
import cx_Oracle
from typing import Optional
from sqlalchemy import create_engine
from hooks.oci_base import OCIBaseHook
from airflow.exceptions import AirflowException


class OCIDBHook(OCIBaseHook):
    """
    Interact with Databases on OCI

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
    def __init__(self,
                 compartment_ocid: str,
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
        super(OCIDBHook, self).__init__(*args, **kwargs)
        self.compartment_id = compartment_ocid
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
        self.oci_client = oci.database.DatabaseClient

    def get_ocid_by_name(self, db_name=None, db_workload=None):
        """
        Look up databases by name and return OCID
        :param db_name: Target DB Name (Not display name)
        :type db_name: str
        :param db_workload: Workload type, valid options are DW or OLTP
        :type db_workload: str
        :return: db_id (OCID)
        """
        try:
            adb_list = \
                self.get_client(self.oci_client).list_autonomous_databases(compartment_id=self.compartment_id,
                                                                           db_workload=self.db_workload).data
            if self.debug is True:
                self.log.info("ADB List: {0}".format(adb_list))
            for db in adb_list:
                if db.db_name == self.db_name:
                    self.database_id = db.id
                    return db.id
                else:
                    continue
            return None
        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])

    def relocalize_sqlnet(self):
        """
        Update the path in $TNS_ADMIN/sqlnet.ora to the correct path
        """
        if self.tns_admin_root is None:
            self.log.error("tns_admin_root not specified or null: {0}".format(self.tns_admin_root))
        else:
            os.environ["TNS_ADMIN"] = self.tns_admin_root
        file_path = os.path.join(os.environ["TNS_ADMIN"], "sqlnet.ora")
        if not os.path.exists(file_path):
            raise Exception("{} does not exist".format(file_path))
        with open(file_path, "r") as fd:
            self.log.info("Reading sqlnet.ora")
            original = fd.read()
        # Set the correct path.
        modified = re.sub(
            'DIRECTORY="([^"]+)"',
            'DIRECTORY="{}"'.format(self.tns_admin_root),
            original,
        )
        with open(file_path, "w") as fd:
            self.log.info("Writing modified sqlnet.ora")
            fd.write(modified)

    def connect(self, **kwargs):
        """
        Connect to an Oracle DSN using a wallet.
        The wallet will be loaded from $TNS_ADMIN/sqlnet.ora.
        If you do not set this, it is assumed to be in your environment.
        :param dsn: The TNS name.
        :type dns: str
        :param tns_admin_root: The wallet root directory.
        :type tns_admin_root: str
        :param **kwargs: Arbitrary keyword arguments to pass to cx_Oracle.connect.
        :return: connection: True if successful, False otherwise.
        """
        try:
            if self.dsn is None:
                if self.db_name is not None:
                    self.dsn = str(self.db_name) + "_medium"
                    if self.debug is True:
                        self.log.info("Connecting to Oracle database with DSN {}".format(self.dsn.lower()))
                    self.connection = cx_Oracle.connect(dsn=self.dsn.lower(), **kwargs)
                else:
                    self.log.error("DB Name and DSN are null, one of these is required to connect")
            else:
                if self.debug is True:
                    self.log.info("Connecting to Oracle database with DSN {}".format(self.dsn))
                self.connection = cx_Oracle.connect(dsn=self.dsn, **kwargs)
            return self.connection
        except AirflowException as e:
            self.log.error(e.response["Error"]["Message"])

    def connect_sqlalchemy(
            self,
            url=None,
            **kwargs
    ):
        """
        Create and return a .Engine instance
        :param url: String that indicates database dialect and connection arguments
        :type url: str
        :param kwargs: Additional arguments supported by create_engine
        :return:
        """
        if url is not None:
            self.engine = create_engine(url, **kwargs)
        else:
            self.engine = create_engine(
                "oracle+cx_oracle://{}:{}@{}".format(self.user_id, self.password, self.dsn), **kwargs
            )
        return self.engine

    def check_state(self, **kwargs):
        """
        Check Database state and return lifecycle_state
        :param kwargs:
        :return:
        """
        db_details = self.get_client(self.oci_client).get_autonomous_database(autonomous_database_id=self.database_id,
                                                                              **kwargs).data
        return db_details.lifecycle_state
