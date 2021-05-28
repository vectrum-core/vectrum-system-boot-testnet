#!/usr/bin/env bash

bioshost=$BIOS_HOSTNAME
if [ -z "$bioshost" ]; then
   bioshost=localhost
fi

biosport=$BIOS_HTTP_PORT
if [ -z "$biosport" ]; then
    biosport=8888
fi

bioscurrencysymbol=$BIOS_CURRENCY_SYMBOL
if [ -z "$bioscurrencysymbol" ]; then
    bioscurrencysymbol="VTM"
fi

# wallet
wddir=vectrum-ignition-wd
wdaddr=localhost:8899
wdurl=http://$wdaddr
#bios node
bioshost=localhost
biosport=8888



vectrum-cli --wallet-url $wdurl --url http://$bioshost:$biosport push action eosio.token transfer '[ "eosio", "vectrum", "1000000.0000 '$bioscurrencysymbol'", "transfer from cli" ]' -p eosio
sleep 1
