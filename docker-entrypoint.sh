#!/bin/dash
set -e

if [ ! -s "$BITCOIN_DATA/bitcoin.conf" ]; then
	cat <<-EOF > "$BITCOIN_DATA/bitcoin.conf"
	printtoconsole=1
	rpcallowip=::/0
	rpcpassword=${BITCOIN_RPC_PASSWORD:-password}
	rpcuser=${BITCOIN_RPC_USER:-bitcoin}
	EOF
fi

exec "$@"
