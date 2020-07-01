# OCI-Airflow
[Apache Airflow](https://airflow.apache.org/) on Oracle Cloud Infrastructure

This Quick Start uses [OCI Resource Manager](https://docs.cloud.oracle.com/iaas/Content/ResourceManager/Concepts/resourcemanager.htm) to make deployment quite easy.  Simply [download the latest .zip](https://github.com/oracle-quickstart/oci-airflow/archive/master.zip) and follow the [Resource Manager instructions](https://docs.cloud.oracle.com/en-us/iaas/Content/ResourceManager/Tasks/managingstacksandjobs.htm) for how to build a stack.

It is highly suggested you use the included schema file to make deployment even easier.   In order to leverage this feature, the GitHub zip must be repackaged so that it's contents are top-level prior to creating the ORM Stack.  This is a straight forward process:

                unzip oci-airflow-master.zip
                cd oci-airflow-master
                zip -r oci-airflow.zip *

Use the `oci-airflow.zip` file created in the last step to create the ORM Stack.  The schema file can even be customized for your use, enabling you to build a set of approved variables for deployment.

This template will build VCN/Subnets as part of deployment, but also has options for using pre-existing VCN/Subnets.  If using pre-existing network topology, ensure you have a security list entry allowing port TCP 8080 ingress/egress for access to the Airflow UI.   Also ensure a gateway is present to allow Internet access for the Airflow host, as Airflow is downloaded and compiled as part of deployment using options selected in the Resource Manager schema.

## Deployment customization

The schema file offers an advanced deployment options.   When enabled you can select which airflow libraries are installed during deployment.   Defaults are for SSH, Oracle, and MySQL. Note that the apache-airflow[mysql] package is required for installation.   If disabled this will result in a deployment failure.

## Metadata Database

This template uses a community edition of MySQL for Airflow metadata.   This is downloaded and installed during provisioning.   The default root database password is set in the [master_boot.sh](https://github.com/oracle-quickstart/oci-airflow/blob/master/scripts/master_boot.sh#L256) which is run in CloudInit.  It's highly suggested you change the password either prior to deployment, or afterwards to something more secure.

*Oracle Database use for Airflow metadata is in development*

## Celery for parallelized execution

This template also supports celery executor to parallelize execution among multiple workers.  If using celery and pre-existing VCN/Subnet, ensure a security list entry is present allowing TCP 5555 ingress/egress for the Flower UI on the Airflow master.

Note that the entry in `/opt/airflow/airflow.cfg` for `fernet_key` will need to be the same on workers as it is for the Airflow master when using local secrets db.  This is something you currently will have to manually set on each worker, in adddition to ensuring `/opt/airflow/dags/` is consistent among all hosts in the cluster, and an API key is present (if using local API key) on each host as well.

*Currently this functionality is in development*

## OCI Hooks, Operators, Sensors

This template automatically downloads and installs hooks, operators, and sensors for OCI services into `/opt/airflow/plugins`.   These plugins are fetched remotely by the airflow master instance from this github repository using `wget` as part of the CloudInit deployment.   Long term these hooks, operators and sensors will be committed upstream to Apache Airflow and be included as part of the native deployment.

## Security
This template does not currently include [Airflow security](https://airflow.apache.org/docs/stable/security.html) out of the box.   It's highly encouraged you enable this after deployment.

## Logging

Deployment activities are logged to `/var/log/OCI-airflow-initialize.log`

This should provide some detail on installation process.  Note that the Airflow UI is not immediately available after Terraform deployment, as the binaries are compiled as part of deployment.   Watching the log file will tell you when the deployment is complete and the Airflow UI is available.

## SystemD 

There are daemon scripts setup as part of deployment.  Airflow can be controlled using systemd commands:

	systemctl (start|stop|status|restart) airflow-webserver
	systemctl (start|stop|status|restart) airflow-scheduler

Also if using celery, the flower service is present on the airflow master, as well as an airflow-worker service on worker nodes.

	systemctl (start|stop|status|restart) flower
	systemctl (start|stop|status|restart) airflow-worker

All services are started during deployment and set to start at boot using chkconfig.
