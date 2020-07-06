# This a very simple example to schedule a Data Flow Application with just a few
# tweaks.
#
# To use this:
# 1. Customize the schedule_interval as needed.
# 2. Set the Application OCID, Compartment OCID.
# 3. If needed, set logs and warehouse buckets.
# 4. If needed, set the oci_namespace variable or create an Airflow Variable (preferred).
# 5. If you want to, customize the display_name variable to change how Runs appear.
# 6. If you want to, customize the SLA setting. SLA misses will appear in the Airflow UI.
#
# After setting these, copy the script into your production DAG directory
# usually (/opt/airflow/dags) and your job will run on the period you specified.

from airflow import DAG
from airflow.models import Variable
from operators.oci_data_flow import OCIDataFlowRun

import datetime

default_args = {
    "owner": "airflow",
    "start_date": datetime.datetime(2020, 6, 26),
    "email": ["your_email@somecompany.com"],
    "email_on_failure": False,
    "email_on_retry": False,
    "sla": datetime.timedelta(hours=12),
}

# This schedule_interval runs the Application every 30 minutes.
# Customize it as needed.
dag = DAG(
    "schedule_dataflow_app",
    default_args=default_args,
    schedule_interval="0/30 * * * *",
    catchup=False,
)

# Customize these variables.
# Find the OCID values in the UI or using the CLI.
oci_conn_id = "oci_default"
dataflow_application_ocid = "UNSET"
compartment_ocid = "UNSET"
logs_bucket = "dataflow-logs"
warehouse_bucket = "dataflow-warehouse"
try:
    namespace = Variable.get("oci_namespace")
except:
    namespace = "UNSET"

# Ensure everything is set.
assert dataflow_application_ocid != "UNSET", "You need to set dataflow_application_ocid"
assert compartment_ocid != "UNSET", "You need to set compartment_ocid"
assert (
    namespace != "UNSET"
), "You need to set namespace as an Airflow variable or in the script"

logs_bucket_uri = f"oci://{logs_bucket}@{namespace}/"
warehouse_bucket_uri = f"oci://{warehouse_bucket}@{namespace}/"
display_name = "Application Run on {{ ds }}"

run_application_step = OCIDataFlowRun(
    task_id="Run_Dataflow_Application",
    compartment_ocid=compartment_ocid,
    application_ocid=dataflow_application_ocid,
    display_name=display_name,
    oci_conn_id=oci_conn_id,
    logs_bucket_uri=logs_bucket_uri,
    warehouse_bucket_uri=warehouse_bucket_uri,
    dag=dag,
)
run_application_step
