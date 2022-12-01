package io.choria.aaasvc

default allow = false

allow {
  input.agent != "choria_provision"
}
