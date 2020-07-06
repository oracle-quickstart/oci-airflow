# To use this example:
# 1. Customize the schedule_interval as needed.
# 2. Set the Application OCID, Compartment OCID.
# 3. If needed, set logs and warehouse buckets.
# 4. If needed, set the oci_namespace variable or create an Airflow Variable (preferred).
# 5. If you want to, customize the display_name variable to change how Runs appear.
# 6. If you want to, customize the SLA setting. SLA misses will appear in the Airflow UI.
#
# Additionally you will need to customize parameter_list.
# The parameters you provide need to be consistent with what your Application expects.
#
# After setting these, copy the script into your production DAG directory
# usually (/opt/airflow/dags) and your job will run on the period you specified.

from airflow import DAG
from airflow.models import Variable
from operators.oci_data_flow import OCIDataFlowRun

import datetime
import oci

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
    "schedule_dataflow_with_parameters",
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

# Set this based on the parameters your Application expects.
parameter_list = [
    oci.data_flow.models.ApplicationParameter(
        name="input_path", value="oci://bucket@namespace/input"
    ),
    oci.data_flow.models.ApplicationParameter(
        name="output_path", value="oci://bucket@namespace/output"
    ),
]

run_application_step = OCIDataFlowRun(
    application_ocid=dataflow_application_ocid,
    compartment_ocid=compartment_ocid,
    dag=dag,
    display_name=display_name,
    logs_bucket_uri=logs_bucket_uri,
    oci_conn_id=oci_conn_id,
    parameters=parameter_list,
    task_id="Run_Dataflow_Application",
    warehouse_bucket_uri=warehouse_bucket_uri,
)
run_application_step
