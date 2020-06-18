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
from hooks.oci_adb import OCIDBHook
import time

class OCIADBSensor(BaseSensorOperator):
    """
    Sensor to interact with OCI ADB
    """

    @apply_defaults
    def __init__(self,
                 compartment_ocid = None,
                 oci_conn_id = 'oci_default',
                 database_id = None,
                 target_state = None,
                 *args,
                 **kwargs):
        super(OCIADBSensor, self).__init__(*args, **kwargs)
        self.compartment_id = compartment_ocid,
        self.oci_conn_id = oci_conn_id,
        self.database_id = database_id,
        self.target_state = target_state,
        self._oci_hook = None

    def poke(self):
        self.log.info('Checking database %s', self.database_id)
        db_state = self.get_oci_hook().check_state(database_id=self.database_id)
        while db_state is not self.target_state:
            self.log.info('DB State: {}'.format(db_state))
            time.sleep(15)
            db_state = self.get_oci_hook().check_state(database_id=self.database_id)

    def get_oci_hook(self):
        """
        Create and return OCI Hook
        :return:
        """
        if not self._oci_hook:
            self._oci_hook = OCIDBHook(compartment_id=self.compartment_id, oci_conn_id=self.oci_conn_id)
            return self._oci_hook
