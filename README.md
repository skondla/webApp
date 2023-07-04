[![license](https://img.shields.io/github/license/mashape/apistatus.svg?maxAge=2592000)](https://github.com/skondla/webApp/blob/master/LICENSE)
[![slack](https://img.shields.io/badge/slack-chat-yellow)](https://join.slack.com/t/devops-zwf1016/shared_invite/zt-1wsafgivm-iI88~ZqZBaKGzYhD8N2JsA)
[![CICD](https://github.com/skondla/webapp/actions/workflows/Deploy-GKE.yml/badge.svg?event=push)](https://github.com/skondla/webApp/actions)
[![CICD](https://github.com/skondla/webapp/actions/workflows/Deploy-EKS.yml/badge.svg?event=push)](https://github.com/skondla/webApp/actions)
[![Deploy webapp to AKS Cluster](https://github.com/skondla/webApp/actions/workflows/Deploy-AKS.yml/badge.svg)](https://github.com/skondla/webApp/actions/workflows/Deploy-AKS.yml)


# Introduction
    This source code is an example of taking an automatic on-demand backup of an RDS instance running in AWS VPC using AWS Python SDK (boto3). Alternatively 
## Setup Instructions:
    $ python3 -V
    Python 3.9.13
    $ pip install -r requirements.txt --user
    #find where to copy libraries - for example
    $ python3 -c "import sys; print(sys.path)"
    output: 

    ['', '/Users/skondla/miniconda3/lib/python39.zip', '/Users/skondla/miniconda3/lib/python3.9', '/Users/skondla/miniconda3/lib/python3.9/lib-dynload', '/Users/skondla/miniconda3/lib/python3.9/site-packages']
### Alternatively cp files in lib directory to common python libriary (check version) 
    sudo cp lib/rdsAdmin.py /Users/skondla/miniconda3/lib/python3.9

    ['', '/Users/skondla/miniconda3/lib/python38.zip', '/Users/skondla/miniconda3/lib/python3.8', '/Users/skondla/miniconda3/lib/python3.8/lib-dynload', '/Users/skondla/miniconda3/lib/python3.8/site-packages']

### Change appConfig.yaml hostname and port matching your host IP
### scheduled to run in cron
    #DB webApp
    */5 * * * * /usr/bin/flock -n /tmp/fullWebapp.lock python /data2/api/db/dbWebAPI.py > /data2/api/db/log 2>&1
    
### How to Access webApp via HTTPS or CURL

##### Main Page

##### https://10.10.x.x:25443/backup

    #create cluster db snapshot  
    curl -k https://10.10.x.x:25443/backup/create \
    --data "endpoint=ecomm-integ-postgresdb-aurora.cluster-ro-vxt3omEzZi92f.us-east-1.rds.amazonaws.com"; \
    --data "endpoint=ecomm-integ-postgresdb-aurora.cluster-ro-f657cdvjhwda.us-east-1.rds.amazonaws.com"; \
    echo
  
    !<---(https://10.10.x.x:25443/backup/create)-->

##### check cluster db snapshot
  
    curl -k https://10.10.x.x:25443/backup/status \
    --data "snapshotname=ecomm-integ-postgresdb-aurora-snapshot-2019-06-23-22-21-57" \
    --data "endpoint=ecomm-integ-postgresdb-aurora.cluster-ro-vxt3omEzZi92f.us-east-1.rds.amazonaws.com"; \
    --data "endpoint=ecomm-integ-postgresdb-aurora.cluster-ro-f657cdvjhwda.us-east-1.rds.amazonaws.com"; \
    echo
    !<---(https://10.10.x.x:25443/backup/status)-->

##### delete cluster db snapshot
  
    curl -k https://10.10.x.x:25443/backup/delete \
    --data "snapshotname=ecomm-integ-postgresdb-aurora-snapshot-2019-06-23-22-21-57" \
    --data "endpoint=ecomm-integ-postgresdb-aurora.cluster-ro-vxt3omEzZi92f.us-east-1.rds.amazonaws.com"; \
    --data "endpoint=ecomm-integ-postgresdb-aurora.cluster-ro-f657cdvjhwda.us-east-1.rds.amazonaws.com"; \
    echo
  
    !<---(https://10.10.x.x:25443/backup/delete)-->


###  Checking Connections
    * Troubleshooting*

  
    admin@ip-10-96-6-124:/data2/api/db$ ps -ef|grep dbWebAPI.py 
    admin    13047 13042  0 21:00 ?        00:00:00 /bin/sh -c /usr/bin/flock -n /tmp/fullWebapp.lock python /data2/api/db/dbWebAPI.py > /data2/api/db/log 2>&1
    admin    13051 13047  0 21:00 ?        00:00:00 /usr/bin/flock -n /tmp/fullWebapp.lock python /data2/api/db/dbWebAPI.py
    admin    13054 13051  6 21:00 ?        00:00:00 python /data2/api/db/dbWebAPI.py
    admin    13256 13054  6 21:00 ?        00:00:00 python /data2/api/db/dbWebAPI.py
    admin    13454 12829  0 21:00 pts/0    00:00:00 grep dbWebAPI.py
    admin@ip-10-96-6-124:/data2/api/db$ netstat -an | grep 10.78.2.42
    tcp        0      0 10.78.2.42:25443       0.0.0.0:*               LISTEN     
    tcp        0     36 10.78.2.42:22          10.200.209.167:63473    ESTABLISHED
    udp        0      0 10.78.2.42:123         0.0.0.0:*                          
    admin@ip-10-96-6-124:/data2/api/db$ lsof -i :25443
    COMMAND   PID  USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
    python  13054 admin    4u  IPv4  38308      0t0  TCP ip-10.78.2.42.datacube.com:25443 (LISTEN)
    python  13256 admin    4u  IPv4  38308      0t0  TCP ip-10.78.2.42.datacube.com:25443 (LISTEN)
  

### Architecture flow

![Alt text](images/dbAPIapp.png)

HTML interface example: 

![Alt text](images/webApp.backups.png)

### DevSecOps pipeline diagram

![Alt text](images/DevSecOps_with_GutHub_Actions.png)

###### Contact: skondla@me.com
###### Blog

[DevSecOps — Deploying WebApp on Google Cloud GKE cluster with Github Actions](https://medium.com/@kondlawork/devsecops-deploying-webapp-on-google-cloud-gke-cluster-with-github-actions-1028c0630dde)

