#!/usr/bin/env bash

set -e

log() {
	echo
	echo ">>>>>>>"
	echo $1
	echo "<<<<<<<"
	echo
}

export EASYRSA_PKI=`pwd`/credentials/ca


if [ -f credentials/issuer/issuer.seed ]
then
  echo "Issuer already exist, please remove credentials/issuer/issuer.seed to recreate credentials"
  exit 1
fi

log "Preparing credentials in ./credentials"

mkdir -p credentials/{issuer,aaasvc,server,broker}

log "Setting up CA"
easyrsa init-pki
easyrsa --batch build-ca nopass

log "Creating Organization Issuer"
choria jwt keys credentials/issuer/issuer.seed credentials/issuer/issuer.public

log "Creating AAA Server Chain Issuer"
choria jwt keys credentials/aaasvc/chain-signer.seed credentials/aaasvc/chain-signer.public
choria jwt client credentials/aaasvc/chain-signer.jwt aaa_chain_delegator credentials/issuer/issuer.seed --public-key $(cat credentials/aaasvc/chain-signer.public) --issuer --no-fleet-management --validity 365d
cp credentials/issuer/issuer.public credentials/aaasvc/

log "Creating AAA Server Request Signer"
choria jwt keys credentials/aaasvc/request-signer.seed credentials/aaasvc/request-signer.public
choria jwt client credentials/aaasvc/request-signer.jwt aaa_request_signer credentials/issuer/issuer.seed --public-key $(cat credentials/aaasvc/request-signer.public) --no-fleet-management --auth-delegation --validity 365d

log "Creating AAA Server Signing Service"
choria jwt keys credentials/aaasvc/signer-service.seed credentials/aaasvc/signer-service.public
choria jwt server credentials/aaasvc/signer-service.jwt aaa.choria.local $(cat credentials/aaasvc/signer-service.public) credentials/issuer/issuer.seed --org choria --collectives choria --service
openssl req -new -nodes -keyout credentials/aaasvc/private.key -out credentials/aaasvc/csr.req -subj "/CN=aaa.choria.local/O=Choria"
easyrsa --batch import-req credentials/aaasvc/csr.req aaasvc
easyrsa --batch sign-req serverClient aaasvc
cp credentials/ca/issued/aaasvc.crt credentials/aaasvc/public.crt

log "Creating broker credentials"
choria jwt keys credentials/broker/broker.seed credentials/broker/broker.public
choria jwt server credentials/broker/broker.jwt broker.choria.local $(cat credentials/broker/broker.public) credentials/issuer/issuer.seed --org choria --collectives choria
openssl req -new -nodes -keyout credentials/broker/private.key -out credentials/broker/csr.req -subj "/CN=broker.choria.local/O=Choria"
easyrsa --batch import-req credentials/broker/csr.req broker
easyrsa --batch sign-req serverClient broker
cp credentials/ca/issued/broker.crt credentials/broker/public.crt
cp credentials/ca/ca.crt credentials/broker
cat config/broker/broker.templ|sed -e "s.ISSUER.$(cat credentials/issuer/issuer.public)." > config/broker/broker.conf


log "Creating issuer signed server"
choria jwt keys credentials/server/server.seed credentials/server/server.public
choria jwt server credentials/server/server.jwt server.choria.local $(cat credentials/server/server.public) credentials/issuer/issuer.seed --org choria --collectives choria
cat config/server/server.templ|sed -e "s.ISSUER.$(cat credentials/issuer/issuer.public)." > config/server/server.conf

log "Creating provisioning.jwt"
choria jwt prov credentials/server/provisioning.jwt credentials/issuer/issuer.seed --token s3cret --urls nats://broker.choria.local:4222 --default

log "Finishing"
find credentials -type d |xargs chmod a+x
find credentials -type f |xargs chmod a+r
