#!/usr/bin/env bash

if [ -z "$FEATURE_DIGESTS" ]; then
   FEATURE_DIGESTS="0ec7e080177b2c02b278d5088611686b49d739925a92d9bfcacd7fc6b74053bd 1a99a59d87e06e09ec5b028a9cbb7749b4a5ad8819004365d02dc4379a8b7241 299dcb6af692324b899b39f16d5a530a33062804e41f09dc97e9f156b4476707 2652f5f96006294109b3dd0bbde63693f55324af452b799ee137a81a905eed25 ef43112c6543b88db2283a2e077278c315ae2c84719a8b25f25cc88565fbea99 4a90c00d55454dc5b059055ca213579c6ea856967712a56017487886a4d4cc0f 4e7bf348da00a945489b2a681749eb56f5de00b900014e137ddae39f48f69d67 4fca8bd82bbd181e714e283f83e1b45d95ca5af40fb89ad3977b653c448f78c2 68dcaa34c0517d19666e6b33add67351d8c5f69e999ca1e37931bc410a297428 8ba52fe7a3956c5cd3a656a3174b931d3bb2abb45578befc59f283ecd816a405 ad9e3d8f650687709fd68f4b90b41f7d825a365b02c23a636cef88ac2ac00c43 e0fb64b1085cc5538970158d05a009c24e276fb94e1a0bf6a528b48fbc4ff526 f0af56d2c5a48d60a4a5b5c903edfb7db3a736a94ed589d0b797df33ff9d3e1d"
fi

bioshost=$BIOS_HOSTNAME
if [ -z "$bioshost" ]; then
   bioshost=localhost
fi

biosport=$BIOS_HTTP_PORT
if [ -z "$biosport" ]; then
    biosport=8888
fi

contracstpath=$CONTRACTS_PATH
if [ -z "$contracstpath" ]; then
    contracstpath="./contracts"
fi

bioscontractpath=$BIOS_CONTRACT_PATH
if [ -z "$bioscontractpath" ]; then
    bioscontractpath="$contracstpath/eosio.bios"
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

logfile=$wddir/bootlog.txt

if [ -e $wddir ]; then
    rm -rf $wddir
fi
mkdir $wddir

step=1
echo Initializing ignition sequence  at $(date) | tee $logfile

echo "FEATURE_DIGESTS: $FEATURE_DIGESTS" >> $logfile

echo "http-server-address = $wdaddr" > $wddir/config.ini

vectrum-wallet --config-dir $wddir --data-dir $wddir --http-max-response-time-ms 99999 2> $wddir/wdlog.txt &
echo $$ > ignition_wallet.pid
echo vectrum-wallet log in $wddir/wdlog.txt >> $logfile
sleep 1

ecmd () {
    echo ===== Start: $step ============ >> $logfile
    echo executing: vectrum-cli --wallet-url $wdurl --url http://$bioshost:$biosport $* | tee -a $logfile
    echo ----------------------- >> $logfile
    vectrum-cli  --wallet-url $wdurl --url http://$bioshost:$biosport $* >> $logfile 2>&1
    echo ==== End: $step ============== >> $logfile
    step=$(($step + 1))
}

wcmd () {
    ecmd wallet $*
}

cacmd () {
    echo ===== Start: $step ============ >> $logfile
    echo 'executing: vectrum-cli  --wallet-url $wdurl --url http://$bioshost:$biosport system newaccount --transfer --stake-net "3571429.0000 '$bioscurrencysymbol'" --stake-cpu "3571429.0000 '$bioscurrencysymbol'"  --buy-ram "10.0000 '$bioscurrencysymbol'" eosio' $* | tee -a $logfile
    echo ----------------------- >> $logfile
    vectrum-cli  --wallet-url $wdurl --url http://$bioshost:$biosport system newaccount --transfer --stake-net "3571429.0000 $bioscurrencysymbol" --stake-cpu "3571429.0000 $bioscurrencysymbol" --buy-ram "10.0000 $bioscurrencysymbol" eosio $* >> $logfile 2>&1
    echo ==== End: $step ============== >> $logfile
    step=$(($step + 1))
    ecmd system regproducer $1 $2
    ecmd push action eosio activprod '["'$1'"]' -p vectrum@active
    ecmd system voteproducer prods $1 $1
}


sleep 2
ecmd get info

wcmd create --to-console -n ignition

# import privkeys to wallet
wcmd import -n ignition --private-key 5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3
#wcmd import -n ignition --private-key 5Jn8JPH7SJKR8y3n9x2a39ywH125bZsCdxw7HarXPz5aWxvCX2D

curl -X POST http://localhost:$biosport/v1/producer/schedule_protocol_feature_activations -d '{"protocol_features_to_activate": ["0ec7e080177b2c02b278d5088611686b49d739925a92d9bfcacd7fc6b74053bd"]}' >> $logfile 2>&1
sleep 1

###INSERT prodkeys
echo "Activated Features Check:" >> $logfile
curl http://$bioshost:$biosport/v1/chain/get_activated_protocol_features >> $logfile
ecmd set contract eosio $contracstpath/eosio.bios@v1.8.3 eosio.bios.wasm eosio.bios.abi
sleep 1

# Preactivate all digests
for digest in $FEATURE_DIGESTS; do
    ecmd push action eosio activate "{\"feature_digest\":\"$digest\"}" -p eosio
done
sleep 1

ecmd set contract eosio $contracstpath/eosio.bios eosio.bios.wasm eosio.bios.abi
sleep 1

# Create required system accounts
#ecmd create key --to-console
#pubsyskey=`grep "^Public key:" $logfile | tail -1 | sed "s/^Public key://"`
#prisyskey=`grep "^Private key:" $logfile | tail -1 | sed "s/^Private key://"`
#echo eosio.* keys: $prisyskey $pubsyskey >> $logfile
echo eosio.* keys: 5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3 EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV >> $logfile
#wcmd import -n ignition --private-key $prisyskey
ecmd create account eosio eosio.bpay EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
ecmd create account eosio eosio.msig EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
ecmd create account eosio eosio.names EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
ecmd create account eosio eosio.ram EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
ecmd create account eosio eosio.ramfee EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
ecmd create account eosio eosio.saving EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
ecmd create account eosio eosio.stake EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
ecmd create account eosio eosio.token EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
ecmd create account eosio eosio.vpay EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
ecmd create account eosio eosio.wrap EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
# vectrum accounts
ecmd create account eosio vectrum EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
ecmd create account eosio vectrumgroup EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
ecmd create account eosio vectrumrobot EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV

ecmd set contract eosio.token $contracstpath/eosio.token eosio.token.wasm eosio.token.abi
sleep 1
ecmd set contract eosio.msig $contracstpath/eosio.msig eosio.msig.wasm eosio.msig.abi
sleep 1
ecmd set contract eosio.wrap $contracstpath/eosio.wrap eosio.wrap.wasm eosio.wrap.abi
sleep 1

echo ===== Start: $step ============ >> $logfile
echo executing: vectrum-cli --wallet-url $wdurl --url http://$bioshost:$biosport push action eosio.token create '[ "eosio", "10000000000.0000 '$bioscurrencysymbol'" ]' -p eosio.token | tee -a $logfile
echo executing: vectrum-cli --wallet-url $wdurl --url http://$bioshost:$biosport push action eosio.token issue '[ "eosio", "1000000000.0000 '$bioscurrencysymbol'", "memo" ]' -p eosio | tee -a $logfile
echo ----------------------- >> $logfile
vectrum-cli --wallet-url $wdurl --url http://$bioshost:$biosport push action eosio.token create '[ "eosio", "10000000000.0000 '$bioscurrencysymbol'" ]' -p eosio.token >> $logfile 2>&1
vectrum-cli --wallet-url $wdurl --url http://$bioshost:$biosport push action eosio.token issue '[ "eosio", "1000000000.0000 '$bioscurrencysymbol'", "memo" ]' -p eosio >> $logfile 2>&1
echo ==== End: $step ============== >> $logfile
step=$(($step + 1))

# setup system contract
ecmd set contract eosio $contracstpath/eosio.system eosio.system.wasm eosio.system.abi
sleep 2
echo executing: vectrum-cli --wallet-url $wdurl --url http://$bioshost:$biosport push action eosio init '[0, "4,'$bioscurrencysymbol'"]' -p eosio | tee -a $logfile
echo ----------------------- >> $logfile
vectrum-cli --wallet-url $wdurl --url http://$bioshost:$biosport push action eosio init '[0, "4,'$bioscurrencysymbol'"]' -p eosio >> $logfile 2>&1
sleep 1

# create producers
cacmd defproducera EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cacmd defproducerb EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cacmd defproducerc EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cacmd defproducerd EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cacmd defproducere EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cacmd defproducerf EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cacmd defproducerg EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cacmd defproducerh EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cacmd defproduceri EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cacmd defproducerj EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cacmd defproducerk EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cacmd defproducerl EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cacmd defproducerm EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cacmd defproducern EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cacmd defproducero EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cacmd defproducerp EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cacmd defproducerq EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cacmd defproducerr EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cacmd defproducers EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cacmd defproducert EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cacmd defproducerv EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
###INSERT cacmd

#pkill -15 vectrum-wallet
