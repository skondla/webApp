#!/bin/bash
#Author: skondla@me.com , Date: 10/21/2019
<<<<<<< HEAD
mkdir certs && cd certs
openssl genrsa -des3 -passout pass:x -out server.pass.key 4096
openssl rsa -passin pass:x -in server.pass.key -out key.pem
rm server.pass.key
openssl req -new -key key.pem -out server.csr \
    -subj "/C=US/ST=CA/L=Irvine/O=XYZ Inc/OU=IT Department/CN=www.xyzinc.com"
openssl x509 -req -days 730 -in server.csr -signkey key.pem -out certificate.pem
cd ..
=======

>>>>>>> 845d64a056d2a6cfbeb4ee75b6cf9b870e7c4931
python3 dbWebAPI.py

