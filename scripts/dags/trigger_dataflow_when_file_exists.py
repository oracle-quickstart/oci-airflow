# To use this example:
# 1. Customize the schedule_interval as needed.
# 2. Set the Application OCID, Compartment OCID and name of the bucket to probe.
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
from sensors.oci_object_storage import OCIObjectStoragePrefixSensor

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
    "transcoder_ng5",
    default_args=default_args,
    schedule_interval="0/30 * * * *",
    catchup=False,
    concurrency=1,
    max_active_runs=1,
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
bucket_name = "UNSET"
bucket_base_path = ""

# Ensure everything is set.
assert bucket_name != "UNSET", "You need to set bucket_name"
assert dataflow_application_ocid != "UNSET", "You need to set dataflow_application_ocid"
assert compartment_ocid != "UNSET", "You need to set compartment_ocid"
assert (
    namespace != "UNSET"
), "You need to set namespace as an Airflow variable or in the script"

logs_bucket_uri = f"oci://{logs_bucket}@{namespace}/"
warehouse_bucket_uri = f"oci://{warehouse_bucket}@{namespace}/"
display_name = "Application Run on {{ ts }}"

def argument_builder_callback(context):
    runtime_arguments = dict()

    # Launch an extra executor for every 10 files, up to 20 total executors.
    total_files = context["task_instance"].xcom_pull(
        "Probe_New_Data", key="oci_prefix_total_files"
    )
    num_executors = min(total_files // 10 + 2, 20)
    runtime_arguments["num_executors"] = num_executors
    runtime_arguments["driver_shape"] = "VM.Standard2.2"
    runtime_arguments["executor_shape"] = "VM.Standard2.2"

    # Set application arguments including parallelism.
    # Target 3 partitions per core (VM.Standard2.2 = 2 cores).
    number_partitions = str(num_executors * 2 * 3)
    runtime_arguments["arguments"] = [
        "--input",
        bucket_name,
        "--output",
        "output",
        "--number-partitions",
        number_partitions,
    ]
    return runtime_arguments

with dag:
    sensor = OCIObjectStoragePrefixSensor(
        task_id="Probe_New_Data",
        bucket_name=bucket_name,
        mode="reschedule",
        prefix=bucket_base_path,
    )
    run_application = OCIDataFlowRun(
        task_id="Run_Dataflow_Application",
        application_ocid=dataflow_application_ocid,
        compartment_ocid=compartment_ocid,
        display_name=display_name,
        logs_bucket_uri=logs_bucket_uri,
        oci_conn_id=oci_conn_id,
        runtime_callback=argument_builder_callback,
        warehouse_bucket_uri=warehouse_bucket_uri,
    )
    sensor >> run_application
