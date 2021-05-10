# Standard Production Ready Cloud Setup on Azure (with AKS) #
This repo is for standard 3-tier microservice based application platform setup on Azure using Azure CLI (IaC). IaC includes only Azure components and make it ready for any kubernetes based application to be deployed (application deployment is not in the scope). <br/><br/>
![plot](./architecture/network_topology.png)

## How do I get set up? ##

> **Configuration**  <br/>
Update paramters/env-{env}.sh file for required azure resources and configuration. <br/>
Note: Resource creation in Azure incur cost, review the configuration before running the script.

> **Usage**  <br/>
./run.sh [OPTIONS]

> **Options** <br/>
-c, --command     Command for script [deploy | destroy] <br/>
-e, --env         Environment for the script [staging | production] <br/>
-l, --log         Print log to file <br/>
-s, --strict      Exit script with null variables.  i.e 'set -o nounset' <br/>
-d, --debug       Runs script in BASH debug mode (set -x) <br/>
-h, --help        Display this help and exit <br/>
--version         Output version information and exit <br/>

> **Example** <br/>
$./run.sh -c deploy -e staging -l <br/>
$./run.sh -c destroy -e staging -l <br/>