#!/usr/bin/env bash

set -e

log() {
	echo
	echo ">>>>>>>"
	echo $1
	echo "<<<<<<<"
	echo
}

export EASYRSA_PKI=`pwd`/pki/ca

log "Preparing a Certificate Authority in ${EASYRSA_PKI}"

easyrsa init-pki

log "We will now create the Certificate Authority"

easyrsa --batch build-ca nopass

log "Creating the provisioning.jwt Key pair in pki/provisioner"

mkdir -p pki/provisioner
openssl genrsa -out pki/provisioner/provisioner-jwt-signer.key 
openssl rsa -in pki/provisioner/provisioner-jwt-signer.key -pubout > pki/provisioner/provisioner-jwt-signer.crt

log "Creating the Node JWT Key pair in pki/provisioner"

mkdir -p pki/provisioner
openssl genrsa -out pki/provisioner/node-jwt-signer.key 
openssl rsa -in pki/provisioner/node-jwt-signer.key -pubout > pki/provisioner/node-jwt-signer.crt

log "Creating the Provisioning Certificates in pki/provisioner"

openssl req -new -nodes -keyout pki/provisioner/private.key -out pki/provisioner/csr.req -subj "/CN=provisioner.choria/O=Choria"
easyrsa --batch import-req pki/provisioner/csr.req provisioner
easyrsa --batch sign-req serverClient provisioner
cp pki/ca/issued/provisioner.crt pki/provisioner/public.crt
cp pki/ca/ca.crt pki/provisioner

log "Creating the AAA Privileged Certificates in pki/aaa"
mkdir -p pki/aaa
openssl req -new -nodes -keyout pki/aaa/aaa-privileged.choria.key -out pki/aaa/csr.req -subj "/CN=aaa-privileged.choria/O=Choria"
easyrsa --batch import-req pki/aaa/csr.req aaa
easyrsa --batch sign-req serverClient aaa
cp pki/ca/issued/aaa.crt pki/aaa/aaa-privileged.choria.crt
cp pki/ca/ca.crt pki/aaa

log "Creating the AAA HTTPS Certificates pki/aaa"
openssl req -new -nodes -keyout pki/aaa/aaa.choria.key -out pki/aaa/tls-csr.req -subj "/CN=aaa.choria/O=Choria"
easyrsa --batch import-req pki/aaa/tls-csr.req aaa_tls
easyrsa --batch sign-req serverClient aaa_tls
cp pki/ca/issued/aaa_tls.crt pki/aaa/aaa.choria.crt

log "Creating certificates for the broker in pki/broker"

mkdir -p pki/broker
openssl req -new -nodes -keyout pki/broker/private.key -out pki/broker/csr.req -subj "/CN=broker.choria/O=Choria"
easyrsa --batch import-req pki/broker/csr.req broker
easyrsa --batch sign-req serverClient broker
cp pki/ca/issued/broker.crt pki/broker/public.crt
cp pki/ca/ca.crt pki/broker
cp pki/provisioner/provisioner-jwt-signer.crt pki/broker
cp pki/provisioner/node-jwt-signer.crt pki/broker
cp pki/aaa/aaa-privileged.choria.crt pki/broker

log "Creating provisioning.jwt for the servers in pki/server"
mkdir -p pki/server
rm -f pki/server/provisioning.jwt
choria tool jwt pki/server/provisioning.jwt pki/provisioner/provisioner-jwt-signer.key --token s3cret --urls nats://broker:4222 --default
choria tool jwt pki/server/provisioning.jwt pki/provisioner/provisioner-jwt-signer.crt
