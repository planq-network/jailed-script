#!/bin/bash

RED="\033[31m"
YELLOW="\033[33m"
GREEN="\033[32m"
NORMAL="\033[0m"

function setup {
  keyname "${1}"
  sleepTime "${2}"
}

function keyname {
  KEY_NAME=${1}
}

function sleepTime {
  STIME=${1:-"10m"}
}

function sendDiscord {
  if [[ {DISCORD_HOOK} != "" ]]; then
    local discord_msg="$@"
    curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$discord_msg\"}" DISCORD_HOOK -so /dev/null
  fi
}

function launch {
setup "${1}" "${2}"
echo "-------------------------------------------------------------------"
echo -e "$YELLOW Enter PASSWORD for your KEY $NORMAL"
echo "-------------------------------------------------------------------"
read -s PASS

RPC_ADDRESS=$(planqd status | jq -r .NodeInfo.other.rpc_address)
COIN=$(planqd query staking params --node ${RPC_ADDRESS} -o j | jq -r '.bond_denom')
ADDRESS=$(echo $PASS | planqd keys show ${KEY_NAME} --output json | jq -r '.address')
VALOPER=$(echo $PASS | planqd keys show ${KEY_NAME} -a --bech val)
CHAIN=$(planqd status --node ${RPC_ADDRESS} 2>&1 | jq -r .NodeInfo.network)
VPOWER=$(planqd status --node ${RPC_ADDRESS} 2>&1 | jq -r .ValidatorInfo.VotingPower)

echo "-------------------------------------------------------------------"
echo -e "$YELLOW Check you Validator data: $NORMAL"
echo -e "$GREEN Address: $ADDRESS $NORMAL"
echo -e "$GREEN Valoper: $VALOPER $NORMAL"
echo -e "$GREEN Voting power: $VPOWER$COIN $NORMAL"
echo -e "$GREEN Chain: $CHAIN $NORMAL"
echo -e "$GREEN Coin: $COIN $NORMAL"
echo -e "$GREEN Key Name: $KEY_NAME $NORMAL"
echo -e "$GREEN Sleep Time: $STIME $NORMAL"
echo "-------------------------------------------------------------------"
echo -e "$YELLOW If your Data is right type$RED yes$NORMAL.$NORMAL"
echo -e "$YELLOW If your Data is wrong type$RED no$NORMAL$YELLOW and check it.$NORMAL $NORMAL"
read -p "Your answer: " ANSWER

if [ "$ANSWER" == "yes" ]; then
    while true
    do
    echo "-------------------------------------------------------------------"
    echo -e "$RED$(date +%F-%H-%M-%S)$NORMAL $YELLOW Start checking the validator state. $NORMAL"
    echo "-------------------------------------------------------------------"
    VPOWER=$(planqd status --node ${RPC_ADDRESS} 2>&1 | jq -r .ValidatorInfo.VotingPower)
    if [[ $VPOWER == 0 ]]; then
        echo "-------------------------------------------------------------------"
        echo -e "$RED$(date +%F-%H-%M-%S)$NORMAL $YELLOW Validator JAILED. $NORMAL"
        echo "-------------------------------------------------------------------"
        MSG=$(echo -e "planqd | $(date +%F-%H-%M-%S) | VALIDATOR JAILED | VOTING POWER ${VPOWER}${COIN}")
        sendDiscord ${MSG}
    else
        echo "-------------------------------------------------------------------"
        echo -e "$YELLOW Validator not Jailed. $NORMAL"
        echo -e "$GREEN Voting power: $VPOWER$COIN $NORMAL"
        echo "-------------------------------------------------------------------"
    fi
        echo "-------------------------------------------------------------------"
        echo -e "$GREEN Sleep for ${STIME} $NORMAL"
        echo "-------------------------------------------------------------------"
        sleep ${STIME}
    done
elif [ "$ANSWER" == "no" ]; then
    echo -e "$RED Exited...$NORMAL"
    exit 0
else
    echo -e "$RED Answer wrong. Exited...$NORMAL"
    exit 0
fi
}

while getopts ":k:s:" o; do
  case "${o}" in
    k)
      k=${OPTARG}
      ;;
    s)
      s=${OPTARG}
      ;;
  esac
done
shift $((OPTIND-1))

launch "${k}" "${s}"
