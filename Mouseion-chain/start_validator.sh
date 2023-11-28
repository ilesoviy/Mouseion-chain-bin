#!/bin/bash

KEYS[0]="nodeval"
CHAINID="mouseion_470-1"
MONIKER="MouseionChain-Node"
# Remember to change to other types of keyring like 'file' in-case exposing to outside world,
# otherwise your balance will be wiped quickly
# The keyring test does not require private key to steal tokens from you
KEYRING="test"
KEYALGO="eth_secp256k1"
LOGLEVEL="info"
# Set dedicated home directory for the mouseiond instance
HOMEDIR="$HOME/.mouseiond"
# to trace evm
#TRACE="--trace"
TRACE=""

TOKEN="amou"

PREFIX="mou"

if [[ $1 == "init" ]]; then
	# Path variables
	CONFIG=$HOMEDIR/config/config.toml
	APP_TOML=$HOMEDIR/config/app.toml
	GENESIS=$HOMEDIR/config/genesis.json

	# validate dependencies are installed
	command -v jq >/dev/null 2>&1 || {
		echo >&2 "jq not installed. More info: https://stedolan.github.io/jq/download/"
		exit 1
	}

	# used to exit on first error (any non-zero exit code)
	set -e

	# Remove the previous folder
	rm -rf "$HOMEDIR"

	make install

	# Set client config
	mouseiond config keyring-backend $KEYRING --home "$HOMEDIR"
	mouseiond config chain-id $CHAINID --home "$HOMEDIR"

	# If keys exist they should be deleted
	for KEY in "${KEYS[@]}"; do
		mouseiond keys add "$KEY" --keyring-backend $KEYRING --algo $KEYALGO --home "$HOMEDIR"
	done

	# Set moniker and chain-id for Evmos (Moniker can be anything, chain-id must be an integer)
	mouseiond init $MONIKER -o --chain-id $CHAINID --home "$HOMEDIR"
	

	sed -i 's/127.0.0.1:26657/0.0.0.0:26657/g' "$CONFIG"
	sed -i 's/127.0.0.1:6060/0.0.0.0:6060/g' "$CONFIG"
	sed -i 's/127.0.0.1/0.0.0.0/g' "$APP_TOML"

	SEEDS='41a2bd439b29b5f76237e595401d60576b9c8270@34.71.175.72:26656'
	#sed -i "s/seeds =.*/seeds = \"$SEEDS\"/g" "$CONFIG"
	sed -i "s/persistent_peers =.*/persistent_peers = \"$SEEDS\"/g" "$CONFIG"

	cp "$HOME/genesis.json" "$GENESIS"

	# set custom pruning settings
	sed -i.bak 's/pruning = "default"/pruning = "custom"/g' "$APP_TOML"
	sed -i.bak 's/pruning-keep-recent = "0"/pruning-keep-recent = "2"/g' "$APP_TOML"
	sed -i.bak 's/pruning-interval = "0"/pruning-interval = "10"/g' "$APP_TOML"



	# Run this to ensure everything worked and that the genesis file is setup correctly
	mouseiond validate-genesis --home "$HOMEDIR"

fi

if [[ $1 == "stake" ]]; then
	mouseiond tx staking create-validator  --amount=100000000000$TOKEN --pubkey=$(mouseiond tendermint show-validator)   --commission-rate="0.10" --commission-max-rate="0.20"  --commission-max-change-rate="0.01"  --min-self-delegation="1000000" --gas="auto"  --gas-prices=1000$TOKEN   --from=nodeval
	exit 0
fi

# Start the node (remove the --pruning=nothing flag if historical queries are not needed)
mouseiond start --metrics "$TRACE" --log_level $LOGLEVEL --minimum-gas-prices=0.0001$TOKEN --json-rpc.api eth,txpool,personal,net,debug,web3 --api.enable --home "$HOMEDIR" 




: << "END"
END
