# VECTRUM system boot

## eosio
- EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV:5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3

## defproducera - defproducerv
- EOS7kzimwvz61NLZNo6MZhfBfHk1XfAjbcDVJxRxrzatppT3UfjNi:5Jn8JPH7SJKR8y3n9x2a39ywH125bZsCdxw7HarXPz5aWxvCX2D


```
sudo apt-get install -y libtinfo5 libicu-dev libicu60

wget http://security.ubuntu.com/ubuntu/pool/main/i/icu/libicu60_60.2-3ubuntu3.1_amd64.deb

wget https://github.com/vectrum-core/vectrum/releases/download/v0.1.0/vectrum_0.1.0-1-ubuntu-18.04_amd64.deb
/usr/bin/dpkg -i vectrum_0.1.0-1-ubuntu-18.04_amd64.deb
```


```
./1_run_node.sh
./2_run_wallet.sh
./3_run_bios_boot.sh
```

https://local.bloks.io/?nodeUrl=http://localhost:8888&coreSymbol=VTM&systemDomain=eosio

   /etc/letsencrypt/live/testoname.com/fullchain.pem
   Your key file has been saved at:
   /etc/letsencrypt/live/testoname.com/privkey.pem

https://testoname.com:4443/v1/chain/get_info

https://local.bloks.io/?nodeUrl=https://testoname.com:4443&coreSymbol=VTM&systemDomain=eosio
