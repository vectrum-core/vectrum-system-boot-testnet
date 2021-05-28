#!/usr/bin/env bash

mkdir -p ./data/node_bios

vectrum-node \
  --data-dir=./data/node_bios \
  --config-dir=./config/node_bios \
  --genesis-json=./config/node_bios/genesis.json \
  3>&1 1>> ./data/node_bios/debug.log 2>&1
