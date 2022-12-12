What?
=====

A Docker Composed based Choria environment with:

 * [Choria Broker](https://choria-io.github.io/go-choria/broker/)
 * [Choria Provisioner](https://choria-io.github.io/provisioner/)
 * [Choria AAA Service](https://choria-io.github.io/aaasvc/)
 * [Choria Server](https://choria-io.github.io/go-choria/server/) including [message submit](https://choria.io/docs/streams/submission/)
 * Choria Client
 * Sample System Info gathering [Autonomous Agent](https://choria.io/docs/autoagents/)
 * Sample [Choria Scout](https://choria.io/docs/scout/) health check
 * Registration data publishing and Choria [Adapters](https://choria.io/docs/adapters/)
 * [Choria Streams](https://choria.io/docs/streams/)

This demonstrates an upcoming deployment method that does not rely on
Certificate Authorities or mTLS for security.

Instead we developed an ed25519 based security system that is now in
use by Servers, Clients, Provisioning and AAA this removes the need
for Certificate Authorities while significantly enhancing the features
of the security system

Primarily this demonstrates the work in [issue #1740](https://github.com/choria-io/go-choria/issues/1740)
as documented in the [ADR](https://choria-io.github.io/go-choria/adr/001/index.html)

There is no Puppet anywhere on this setup, it's self provisioning and
self configuring. This will form the basis of deployments in Enterprises
and in Kubernetes environments where we cannot rely on Puppet.

Network?
========

We create 3 networks with the various components deployed, no TCP traffic can move from Client to Servers directly.

![Network Layout](network.png)

**NOTE:** While this shows 2 seperate AAA components, in this case we deploy one process that runs 2 services.

Status?
=======

As mentioned this is our test bed for playing with in-flight work, as
such we cannot guarantee this setup will remain stable.

These features are likely to see a release in January 2023 in Choria 0.27.0.

Requirements?
=============

You need docker with docker compose, this probably only works on Linux and Macs.

Setup?
======

Run `./setup.sh` that will create many certificates, JWT tokens etc

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
activate without requiring restart of the nodes.

Choria Streams?
===============

[Choria Streams](https://choria.io/docs/streams/) is enabled by default and usable
from the `admin` user.

