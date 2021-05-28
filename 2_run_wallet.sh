#!/usr/bin/env bash

mkdir -p ./data/wallet

vectrum-wallet \
  --data-dir=./data/wallet \
  --config-dir=./config/wallet \
  3>&1 1>> ./data/wallet/debug.log 2>&1
