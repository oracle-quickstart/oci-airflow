from datetime import datetime
from airflow import DAG
from hooks.oci_base import OCIBaseHook
from hooks.oci_object_storage import OCIObjectStorageHook
from operators.oci_object_storage import MakeBucket

default_args = {'owner': 'airflow',
                'start_date': datetime(2020, 5, 26),
                'email': ['your_email@somecompany.com'],
                'email_on_failure': False,
                'email_on_retry': False
                }

dag = DAG('oci_simple_example',
          default_args=default_args,
          schedule_interval='@hourly',
          catchup=False
          )

oci_conn_id = "oci_default"
bucketname = "SomeBucketName"
compartment_ocid = "COMPARTMENT_OCID"

with dag:
    make_bucket = MakeBucket(task_id='Make_Bucket', bucket_name=bucketname,oci_conn_id=oci_conn_id, compartment_ocid=compartment_ocid)

    make_bucket
