#!/bin/bash

# TODO: Modify the following environment variables as you need

# Environment Variables for the FTS/Rucio machine
COMPOSE_PROJECT=${COMPOSE_PROJECT:-native} # project to start docker-compose.yml file for fts
RUCIO_NODE=${RUCIO_NODE:-rucio} # container name of the 'rucio' container
FTS_NODE=${FTS_NODE:-fts-dev} # container name of the 'fts' container
FTSDB_NODE=${FTSDB_NODE:-ftsdb} # container name of the 'ftsdb' container
FTS_HOST=${FTS_HOST:-fts} # host/domain name of the 'fts' container
RUCIO_HOST=${RUCIO_HOST:-rucio} # host/domain name of the 'rucio container


# Environment Variables for the Xrootd
XRD1_HOST=${XRD1_HOST:-xrd1}
XRD2_HOST=${XRD2_HOST:-xrd2}
XRD3_HOST=${XRD3_HOST:-xrd3}
SSH_USER=${SSH_USER:-centos} # assume all the xrootd machines use the same ssh user name


# Environment Variables for IPs and Ports
export RUCIO_IP=${RUCIO_IP:-10.0.0.250}
export XRD1_IP=${XRD1_IP:-10.0.0.251}
export XRD2_IP=${XRD2_IP:-10.0.0.252}
export XRD3_IP=${XRD3_IP:-10.0.0.253}
export XRD1_PORT=${XRD1_PORT:-1094}
export XRD2_PORT=${XRD2_PORT:-1094}
export XRD3_PORT=${XRD3_PORT:-1094}

