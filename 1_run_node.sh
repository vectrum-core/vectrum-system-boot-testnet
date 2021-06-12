#!/usr/bin/env bash

mkdir -p ./data/node_bios

#  --hard-replay-blockchain \
#  --disable-replay-opts \
vectrum-node \
  --data-dir=./data/node_bios \
  --config-dir=./config/node_bios \
  --genesis-json=./config/node_bios/genesis.json \
  --disable-replay-opts \
  3>&1 1>> ./data/node_bios/debug.log 2>&1
