#!/bin/bash
# Create a Cluster Root CA
#openssl genrsa -out ${PATH_ROOT}/ssl/ca-key.pem 2048
#openssl req -x509 -new -nodes -key ${PATH_ROOT}/ssl/ca-key.pem -days 10000 -out ${PATH_ROOT}/ssl/ca.pem -subj "/CN=kube-ca"

# Generate the API Server Keypair
openssl genrsa -out ${PATH_ROOT}/ssl/apiserver-key.pem 2048
openssl req -new -key ${PATH_ROOT}/ssl/apiserver-key.pem -out ${PATH_ROOT}/ssl/apiserver.csr -subj "/CN=kube-apiserver" -config ${PATH_ROOT}/ssl/openssl.cnf
openssl x509 -req -in ${PATH_ROOT}/ssl/apiserver.csr -CA ${PATH_ROOT}/ssl/ca.pem -CAkey ${PATH_ROOT}/ssl/ca-key.pem -CAcreateserial -out ${PATH_ROOT}/ssl/apiserver.pem -days 365 -extensions v3_req -extfile ${PATH_ROOT}/ssl/openssl.cnf

# Generate the Kubernetes Worker Keypair
openssl genrsa -out ${PATH_ROOT}/ssl/worker-key.pem 2048
openssl req -new -key ${PATH_ROOT}/ssl/worker-key.pem -out ${PATH_ROOT}/ssl/worker.csr -subj "/CN=kube-worker"
openssl x509 -req -in ${PATH_ROOT}/ssl/worker.csr -CA ${PATH_ROOT}/ssl/ca.pem -CAkey ${PATH_ROOT}/ssl/ca-key.pem -CAcreateserial -out ${PATH_ROOT}/ssl/worker.pem -days 365

# Generate the Cluster Administrator Keypair
openssl genrsa -out ${PATH_ROOT}/ssl/admin-key.pem 2048
openssl req -new -key ${PATH_ROOT}/ssl/admin-key.pem -out ${PATH_ROOT}/ssl/admin.csr -subj "/CN=kube-admin"
openssl x509 -req -in ${PATH_ROOT}/ssl/admin.csr -CA ${PATH_ROOT}/ssl/ca.pem -CAkey ${PATH_ROOT}/ssl/ca-key.pem -CAcreateserial -out ${PATH_ROOT}/ssl/admin.pem -days 365
