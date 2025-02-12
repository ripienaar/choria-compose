#!/usr/bin/env bash

set -e

log() {
	echo
	echo ">>>>>>>"
	echo $1
	echo "<<<<<<<"
	echo
}

if [ -f credentials/issuer/issuer.seed ]
then
  if [ -z ${SILENT_EXIT} ]
  then
    log "Issuer already exist, please remove credentials/issuer/issuer.seed to recreate credentials"
    exit 1
  else
    log "Issuer already exist, continuing startup"
    exit 0
  fi
fi

log "Preparing credentials in ./credentials"

mkdir -p credentials/{issuer,aaasvc,server,broker,provisioner,stream-replicator}

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
openssl genrsa -out credentials/aaasvc/private.key 2048
openssl req -new -x509 -sha256 -key credentials/aaasvc/private.key -out credentials/aaasvc/public.crt -days 365 -subj "/O=Choria.io/CN=aaa.choria.local" -addext "subjectAltName = DNS:aaa.choria.local"

log "Creating broker credentials"
choria jwt keys credentials/broker/broker.seed credentials/broker/broker.public
choria jwt server credentials/broker/broker.jwt broker.choria.local $(cat credentials/broker/broker.public) credentials/issuer/issuer.seed --org choria --collectives choria --subjects 'choria.node_metadata.>'
openssl genrsa -out credentials/broker/private.key 2048
openssl req -new -x509 -sha256 -key credentials/broker/private.key -out credentials/broker/public.crt -days 365 -subj "/O=Choria.io/CN=broker.choria.local" -addext "subjectAltName = DNS:broker.choria.local"
cat config/broker/broker.templ|sed -e "s.ISSUER.$(cat credentials/issuer/issuer.public)." > config/broker/broker.conf

log "Creating provisioning.jwt"
choria jwt prov credentials/server/provisioning.jwt credentials/issuer/issuer.seed --token s3cret --urls nats://broker.choria.local:4222 --default --protocol-v2 --insecure --update --validity 365d

log "Configuring plugins"
plugins=$(choria machine plugins pack config/server/plugins.json credentials/issuer/issuer.seed)
echo "{\"spec\": ${plugins}}" > config/server/machine/external_agents/machine_data.json
ls -l config/server/machine/external_agents/machine_data.json
rm -rf config/server/machines/eam_requests
rm -rf config/server/lib/mcollective/agent/requests

log "Creating provisioner credentials"
choria jwt keys credentials/provisioner/signer.seed credentials/provisioner/signer.public
choria jwt client credentials/provisioner/signer.jwt provisioner_signer credentials/issuer/issuer.seed --public-key $(cat credentials/provisioner/signer.public) --server-provisioner --validity 365d --issuer
cat config/provisioner/provisioner.templ|sed -e "s.ISSUER.$(cat credentials/issuer/issuer.public)." > config/provisioner/provisioner.yaml
cat config/provisioner/helper.templ|sed -e "s.ISSUER.$(cat credentials/issuer/issuer.public)." > config/provisioner/helper.rb
chmod a+x config/provisioner/helper.rb

log "Creating replicator credentials"
choria jwt keys credentials/stream-replicator/choria.seed credentials/stream-replicator/choria.public
choria jwt client credentials/stream-replicator/choria.jwt stream_replicator credentials/issuer/issuer.seed --public-key $(cat credentials/stream-replicator/choria.public) --validity 365d --no-fleet-management --stream-user --publish "choria.stream-replicator.sync.>" --publish "choria.node_advisories.>" --subscribe "choria.stream-replicator.sync.>" --publish "choria.node_metadata._monitor"

log "Finishing"

find credentials -type d |xargs chmod a+x
find credentials -type f |xargs chmod a+r
