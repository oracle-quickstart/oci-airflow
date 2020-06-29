# oci-airflow
[Apache Airflow](https://airflow.apache.org/) on Oracle Cloud Infrastructure

This Quick Start uses [OCI Resource Manager](https://docs.cloud.oracle.com/iaas/Content/ResourceManager/Concepts/resourcemanager.htm) to make deployment quite easy.  Simply [download the latest .zip](archive/master.zip) and follow the [Resource Manager instructions](https://docs.cloud.oracle.com/iaas/Content/ResourceManager/Tasks/usingconsole.htm) for how to build a stack.

It is highly suggested you use the included schema file to make deployment even easier.   In order to leverage this feature, the GitHub zip must be repackaged so that it's contents are top-level prior to creating the ORM Stack.  This is a straight forward process:

                unzip oci-airflow-master.zip
                cd oci-airflow-master
                zip -r oci-airflow.zip *

Use the `oci-airflow.zip` file created in the last step to create the ORM Stack.  The schema file can even be customized for your use, enabling you to build a set of approved variables for deployment.

This template will build VCN/Subnets as part of deployment, but also has options for using pre-existing VCN/Subnets.   

## Celery for parallelized execution

This template also supports celery executor to parallelize execution among multiple workers.   *Currently this functionality is in development*

## OCI Hooks, Operators, Sensors

This template automatically downloads and installs hooks, operators, and sensors for OCI services into /opt/airflow/plugins.   These plugins are fetched remotely by the airflow master instance from this github repository using wget as part of the CloudInit deployment.   Long term these hooks, operators and sensors will be committed upstream to Apache Airflow and be included as part of the native deployment.

## Security
This template does not currently include [Airflow security](https://airflow.apache.org/docs/stable/security.html) out of the box.   It's highly encouraged you enable this after deployment.
