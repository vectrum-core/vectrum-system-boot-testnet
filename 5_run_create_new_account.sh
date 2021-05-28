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



vectrum-cli  --wallet-url $wdurl --url http://$bioshost:$biosport system newaccount --transfer --stake-net "1.0000 $bioscurrencysymbol" --stake-cpu "1.0000 $bioscurrencysymbol" --buy-ram "1.0000 $bioscurrencysymbol" eosio vectrum.user EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV

