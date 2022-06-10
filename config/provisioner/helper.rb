#!/usr/bin/ruby

require "json"
require "yaml"
require "base64"
require "net/http"
require "openssl"

BROKERS = "nats://broker.choria:4222"


def empty_reply
  {
    "defer" => false,
    "msg" => "",
    "certificate" => "",
    "ca" => "",
    "configuration" => {},
    "server_claims" => {}
  }
end

def parse_input
  input = STDIN.read
  request = JSON.parse(input)
  request["inventory"] = JSON.parse(request["inventory"])

  request
end

def validate!(request, reply)
  if request["identity"] && request["identity"].length == 0
    reply["msg"] = "No identity received in request"
    reply["defer"] = true
    return false
  end

  unless request["ed25519_pubkey"]
    reply["msg"] = "No ed15519 public key received"
    reply["defer"] = true
    return false
  end

  unless request["ed25519_pubkey"]
    reply["msg"] = "No ed15519 directory received"
    reply["defer"] = true
    return false
  end

  if request["ed25519_pubkey"]["directory"].length == 0
    reply["msg"] = "No ed15519 directory received"
    reply["defer"] = true
    return false
  end

  true
end

def publish_reply(reply)
  puts reply.to_json
end

def publish_reply!(reply)
  publish_reply(reply)
  exit
end

def set_config!(request, reply)
  reply["configuration"].merge!(
    "identity" => request["identity"],
    "loglevel" => "info",
    "plugin.security.server_anon_tls" => "true",
    "registerinterval" => "300",
    "plugin.choria.server.provision" => "false",
    "plugin.choria.middleware_hosts" => BROKERS,
    "plugin.choria.machine.store" => "/etc/choria/machine",
    "rpcauthorization" => "0",
    "plugin.choria.status_file_path" => "/tmp/choria-status.json",
    "plugin.choria.status_update_interval" => "30"
  )

  reply["server_claims"].merge!(
    "exp" => 5*60*60*24*365,
    "permissions" => {
      "streams" => true
    }
  )
end

reply = empty_reply

begin
  request = parse_input

  reply["msg"] = "Validating"
  unless validate!(request, reply)
    publish_reply!(reply)
  end

  reply["msg"] = "Config"
  set_config!(request, reply)

  reply["msg"] = "Done"
  publish_reply!(reply)
rescue SystemExit
rescue Exception
  reply["msg"] = "Unexpected failure during provisioning: %s: %s" % [$!.class, $!.to_s]
  reply["defer"] = true
  publish_reply!(reply)
end
