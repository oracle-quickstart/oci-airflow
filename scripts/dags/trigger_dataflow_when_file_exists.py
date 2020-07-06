# This example shows:
#
# 1. How to probe for files in an object store location using a sensor.
# 2. Kicking off a Data Flow Run when files exist.
# 3. Using the runtime callback to adjust the Run based on the matching files.
# 4. Use the prefix sensor XCom to get the actual list of files from the sensor.
# 5. Use the prefix sensor XCom to get the file count and size the Run on the fly.

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
    "provide_context": True,
    "retry_delay": datetime.timedelta(seconds=120),
    "sla": datetime.timedelta(hours=12),
}

# Customize these variables.
# Find the OCID values in the UI or using the CLI.
oci_conn_id = "oci_default"
dataflow_application_ocid = "UNSET"
compartment_ocid = "UNSET"
bucket_name = "UNSET"
bucket_base_path = "UNSET"
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
assert bucket_name != "UNSET", "You need to set bucket_name"
assert bucket_base_path != "UNSET", "You need to set bucket_base_path"

logs_bucket_uri = f"oci://{logs_bucket}@{namespace}/"
warehouse_bucket_uri = f"oci://{warehouse_bucket}@{namespace}/"
display_name = "Application Run on {{ ts_nodash }}"

dag = DAG(
    "trigger_dataflow_when_file_exists",
    catchup=False,
    concurrency=1,
    default_args=default_args,
    max_active_runs=1,
)


def argument_builder_callback(context):
    runtime_arguments = dict()

    # Launch an extra executor for every 10 files, up to 20 total executors.
    total_files = context["task_instance"].xcom_pull(
        "Probe_New_Data", key="oci_prefix_total_files"
    )
    num_executors = min(total_files // 10 + 1, 20)
    runtime_arguments["num_executors"] = num_executors

    # Set application parameters including parallelism.
    number_partitions = str(num_executors * 5)
    runtime_arguments["parameters"] = [
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
        prefix=f"{bucket_base_path}",
        soft_fail=True,
    )
    run_application = OCIDataFlowRun(
        application_ocid=dataflow_application_ocid,
        compartment_ocid=compartment_ocid,
        display_name=display_name,
        logs_bucket_uri=logs_bucket_uri,
        oci_conn_id=oci_conn_id,
        runtime_callback=argument_builder_callback,
        task_id="Launch_Dataflow_Application",
        warehouse_bucket_uri=warehouse_bucket_uri,
    )
    sensor >> run_application
