What?
=====

A Docker Composed based Choria environment with:

 * Choria Broker
 * Choria Provisioner (TODO)
 * Choria AAA Server
 * Choria Server
 * Choria Client

There is no Puppet anywhere on this setup, it's self provisioning and
self configuring.

The environment is provisioned with ED25519 keys, clients and servers
do not have TLS certificates other than for opening listening ports
where it is required.

Requirements?
=============

You need `easyrsa` and the `choria` binary on the machine you run this.
For the `choria` binary, at the moment, this must be a nightly build from
the [Nightly](https://yum.eu.choria.io/nightly/binaries/linux/) repo:

Setup?
======

Run `./setup.sh` that will create many certificates, JWT tokens etc, ensure
the `easyrsa` binary is in your path.

Run `docker-compose up --scale server.choria=10` to run 10 Choria servers.

Run `docker-compose exec client.choria bash -l` to get a shell.

Once in the shell do:

```
$ choria login
? Username:  choria
? Password:  ******
Token saved to /home/choria/.choria/token
```

The password is `secret`.

From there basics like `choria req choria_util info` will function until your
JWT expire in a hour.

The `choria` user above is a basic user, there's also an `admin` user with full
access to all subjects on the broker.

For example `choria` could not do `choria broker s backup CHORIA_EVENTS /tmp/events`
while the `admin` user can.

Autonomous Agents?
==================

The server instances are configured to support [Autonomous Agents](https://choria.io/docs/autoagents/)
with an example in `config/server/machine/choria`, any others you add there will immediately
activate without requiring restart of the nodes
