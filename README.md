What?
=====

A Docker Composed based Choria environment with:

 * Choria Broker
 * Choria Provisioner
 * Choria AAA Server
 * Choria Server
 * Choria Client

There is no Puppet anywhere on this setup, it's self provisioning and
self configuring.

The environment is provisioned with ED25519 keys, clients and servers
do not have TLS certificates.

Requirements?
=============

You need `easyrsa` and the `choria` binary on the machine you run this.
For the `choria` binary, at the moment, this must be a nightly build from
the [Nightly](https://yum.eu.choria.io/nightly/binaries/linux/) repo:

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


