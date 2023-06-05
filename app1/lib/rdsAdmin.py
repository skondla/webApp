#!/usr/bin/env python
# Author: Sudheer Kondla, 04/21/17, skondla@me.com
# Purpose: RDS Instance Administration
#coding=utf-8

import boto3
import sys
import json

class RDSCreate:

    def rds_create_db_cluster_snapshot(self, snapshotName, dbname, tagName):
        client = boto3.client('rds')
        response = client.create_db_cluster_snapshot(DBClusterSnapshotIdentifier=snapshotName, DBClusterIdentifier=dbname,
                                                 Tags=[{'Key': 'Name', 'Value': tagName}, ])
        print(response)


    def rds_create_db_snapshot(self, snapshotName, dbname, tagName):
        client = boto3.client('rds')
        response = client.create_db_snapshot(DBSnapshotIdentifier=snapshotName, DBInstanceIdentifier=dbname,
                                         Tags=[{'Key': 'Name', 'Value': tagName}, ])
        print(response)

class RDSDelete:
    def rds_delete_db_cluster_snapshot(self, snapshotName):
        client = boto3.client('rds')
        response = client.delete_db_cluster_snapshot(DBClusterSnapshotIdentifier=snapshotName)
        print(response)

    def delete_db_snapshot(self,dbSnapshotName):
        client = boto3.client('rds')
        response = client.delete_db_snapshot(
            DBSnapshotIdentifier=dbSnapshotName
        )
        print(response)
 
class RDSDescribe:
    def rds_desc_db_instances(self, dbname):
        client = boto3.client('rds')
        response = client.describe_db_instances(DBInstanceIdentifier=dbname)
        print(response)

    def describe_db_cluster_snapshots(self, snapshotName):
        client = boto3.client('rds')
        response = client.describe_db_cluster_snapshots(
            DBClusterSnapshotIdentifier=snapshotName,
        )
        print(response)
    def db_cluster_snapshot_status(self, snapshotName):
        client = boto3.client('rds')
        response = client.describe_db_cluster_snapshots(
            DBClusterSnapshotIdentifier=snapshotName,
        )
        return response['DBClusterSnapshots'][0]['Status']

    #jsbeautifier response

    def describe_db_clusters(self, dbClusterName):
        client = boto3.client('rds')
        response = client.describe_db_clusters(
            DBClusterIdentifier=dbClusterName)
        print(response)

    def describe_db_snapshots(self, dbSnapshotName):
        client = boto3.client('rds')
        response = client.describe_db_snapshots(
        DBSnapshotIdentifier=dbSnapshotName
        )
        print(response)

    def db_snapshot_status(self, dbSnapshotName):
        client = boto3.client('rds')
        response = client.describe_db_snapshots(
        DBSnapshotIdentifier=dbSnapshotName
        )
        return response['DBSnapshots'][0]['Status']
        

