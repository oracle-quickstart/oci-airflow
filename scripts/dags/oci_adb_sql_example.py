from datetime import datetime
from airflow import DAG
from sys import modules
from operators.oci_adb import OCIDBOperator

default_args = {'owner': 'airflow',
                'start_date': datetime(2020, 5, 26),
                'email': ['your.email@somecompany.com'],
                'email_on_failure': False,
                'email_on_retry': False
                }

dag = DAG('oci_adb_sql_example',
          default_args=default_args,
          schedule_interval='@hourly',
          catchup=False
          )

oci_conn_id = "oci_default"
bucketname = "BUCKET_NAME"
db_name = "DATABASE_NAME"
compartment_ocid = "COMPARTMENT OCID"
db_workload = "DW"
tns_admin_root = "/path/to/tns_admin/"
user_id = "DATABASE_USER"
password = "DATABASE_PASSWORD"
drop_table = "DROP TABLE python_modules PURGE"
create_table = """
CREATE TABLE python_modules ( 
module_name VARCHAR2(100) NOT NULL, 
file_path VARCHAR2(300) NOT NULL ) 
"""
many_sql_data = []
for m_name, m_info in modules.items():
    try:
        many_sql_data.append((m_name, m_info.__file__))
    except AttributeError:
        pass
many_sql="INSERT INTO python_modules(module_name, file_path) VALUES (:1, :2)"
debug = True

with dag:
    t1 = OCIDBOperator(task_id='drop_table', compartment_ocid=compartment_ocid, db_name=db_name,
                            db_workload=db_workload, tns_admin_root=tns_admin_root, user_id=user_id,
                            password=password, single_sql=drop_table, debug=debug)
    t2 = OCIDBOperator(task_id='create_table', compartment_ocid=compartment_ocid, db_name=db_name,
                            db_workload=db_workload, tns_admin_root=tns_admin_root, user_id=user_id,
                            password=password, single_sql=create_table, debug=debug)
    t3 =  OCIDBOperator(task_id='insert_data', compartment_ocid=compartment_ocid, db_name=db_name,
                            db_workload=db_workload, tns_admin_root=tns_admin_root, user_id=user_id,
                            password=password, many_sql=many_sql, many_sql_data=many_sql_data, debug=debug)
    t1 >> t2 >> t3

