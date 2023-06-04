#!/usr/bin/env python
#Author: skondla@me.com
#purpose: Build a simple python WebApp & REST API to call database service requests
#coding=utf-8
from flask import Flask, request, render_template, jsonify, Response, escape
from flask_restful import reqparse, abort, Api, Resource
from rdsAdmin import RDSDescribe, RDSCreate, RDSDelete
import sys
import datetime
import yaml
import ssl

sys.path.append('/app/')

#store Global variables
__dbEndPoint__ = ''
__snapshotStatus__ = ''

app = Flask(__name__)

@app.route('/backup')
def my_form():
    return render_template('db-backup-tool.html')

@app.route('/backup/create')
def backup_create():
    return render_template('create-backup.html')

@app.route('/backup/create', methods=['POST'])
def create_backup():
    endPoint = request.form['endpoint']
    __dbEndPoint__  = endPoint
    dbInstance = str(endPoint.strip().split('.')[0])
    today = datetime.datetime.now().strftime("%Y-%m-%d-%H-%M-%S")
    tagName='snapshot'
    snapshotName = dbInstance + '-' + tagName + '-' + today
    requestDBSnapshot = createSnapshot(snapshotName,dbInstance,tagName,endPoint)
    print(str(requestDBSnapshot))
    endPoint = __dbEndPoint__ 
    snapStatus = snapshotStaus(snapshotName,endPoint) 
    return "Snapshot: " + str(escape(snapshotName)) + " requested is successfully submitted \n\n db endpoint: " + escape(endPoint) + '\n\n Snapshot Status: ' + \
        str(escape(snapStatus)), 202

@app.route('/backup/status')
def backup_check():
    return render_template('check-backup.html')

#@app.route('/backup/status', methods=['POST'])
@app.route('/backup/status', methods=['GET', 'POST'])
def backup_status():
    snapshotName = request.form['snapshotname']
    snapshotName = snapshotName.strip()
    endPoint = request.form['endpoint']
    endPoint = endPoint.strip()
    snapStatus = snapshotStaus (snapshotName,endPoint)
    return "Snapshot Status: " + str(snapStatus), 202

@app.route('/backup/delete')
def backup_delete():
    return render_template('delete-backup.html')

@app.route('/backup/delete', methods=['POST'])
def delete_post():
    snapshotName = request.form['snapshotname']
    snapshotName = snapshotName.strip()
    endPoint = request.form['endpoint']
    endPoint = endPoint.strip()
    deleteSnapshot(snapshotName,endPoint)
    return "Snapshot: " + escape(snapshotName) + " deleting...."
    #return "Snapshot: " + snapshotName + " deleting...."

@app.route('/data')
def names():
    data = {"names": ["Sudheer", "Kondla", "Neil", "Nikhil"]}
    return jsonify(data)

def snapshotStaus(snapshotName,dBURL):
    if 'cluster' in dBURL:
        print (dBURL + ' is a cluster')
        return RDSDescribe().db_cluster_snapshot_status(snapshotName)
    else:
        print (dBURL + ' is NOT a cluster')
        return RDSDescribe().db_snapshot_status(snapshotName)

def dbInstanceInfo(instanceName,string):
    if 'cluster' in string:
        print (string + ' is a cluster')
        return RDSDescribe().describe_db_clusters(instanceName)
    else:
        print (string + ' is NOT a cluster')
        return RDSDescribe().rds_desc_db_instances(instanceName)

def createSnapshot(snapshotName, instanceName, tagName, string):
    if 'cluster' in string:
        print (string + ' is a cluster')
        return RDSCreate().rds_create_db_cluster_snapshot(snapshotName,instanceName,tagName)
    else:
        print (string + ' is NOT a cluster')
        return RDSCreate().rds_create_db_snapshot(snapshotName,instanceName,tagName)

def deleteSnapshot(snapshotName,dBURL):
    if 'cluster' in dBURL:
        print (dBURL + ' is a cluster')
        return RDSDelete().rds_delete_db_cluster_snapshot(snapshotName)
    else:
        print (dBURL + ' is NOT a cluster')
        return RDSDelete().delete_db_snapshot(snapshotName)

def appConfig():
    with open('appConfig.yaml', 'r') as f:
        doc = yaml.load(f, Loader=yaml.FullLoader)
        hostname = doc["appConfig"]["hostname"]
        port = doc["appConfig"]["port"]
        config = {hostname,port}
        return config

if __name__ == '__main__':
   sys.path.append('/app/')
   with open('/app/config/appConfig.yaml', 'r') as f:
    doc = yaml.load(f, Loader=yaml.FullLoader)
    hostname = str(doc["appConfig"]["hostname"])
    port = str(doc["appConfig"]["port"])
    certificate = str(doc["appConfig"]["certificate"])
    key = str(doc["appConfig"]["key"])
   #app.run(debug=True)	
   context = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)
   context.load_cert_chain(certificate,key)	
   app.run(host=hostname, port=port, ssl_context=(context),threaded=True) 
   #app.run(host=hostname, port=port, debug=True,ssl_context=(context),threaded=True)
   #app.run(host=hostname, port=port, debug=True,threaded=True)
