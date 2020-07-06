# A smoke test to ensure your environment works.

import datetime

import oci

from airflow import DAG
from airflow.models.baseoperator import BaseOperator
from airflow.utils.decorators import apply_defaults
from hooks.oci_base import OCIBaseHook


# The smoke test loads the object storage namespace.
class SmokeTestOperator(BaseOperator):
    @apply_defaults
    def __init__(self, oci_conn_id: str, *args, **kwargs):
        self.oci_conn_id = oci_conn_id
        super().__init__(*args, **kwargs)

    def execute(self, context):
        self.hook = OCIBaseHook(self.oci_conn_id)
        object_store_client = self.hook.get_client(
            oci.object_storage.ObjectStorageClient
        )
        self.hook.validate_config()
        namespace = object_store_client.get_namespace().data
        self.log.info(f"Namespace is {namespace}")


default_args = {
    "owner": "airflow",
    "start_date": datetime.datetime(2020, 7, 1),
    "email": ["your_email@somecompany.com"],
    "email_on_failure": False,
    "email_on_retry": False,
}

# This schedule_interval runs the Application every 30 minutes.
# Customize it as needed.
dag = DAG(
    "oci_smoke_test",
    default_args=default_args,
    schedule_interval="0 * * * *",
    catchup=False,
)

# Customize the connection you want to use.
oci_conn_id = "oci_default"

smoke_test_step = SmokeTestOperator(
    task_id="oci_smoke_test", oci_conn_id=oci_conn_id, dag=dag,
)
smoke_test_step
