FROM debian:stretch-slim as builder

RUN set -ex \
	&& apt-get update \
	&& apt-get install -qq --no-install-recommends ca-certificates dirmngr gpg wget \
	&& rm -rf /var/lib/apt/lists/*

ENV BITCOIN_VERSION=0.17.0
ENV BITCOIN_URL=https://bitcoincore.org/bin/bitcoin-core-$BITCOIN_VERSION/bitcoin-$BITCOIN_VERSION-x86_64-linux-gnu.tar.gz \
	BITCOIN_SHA256=9d6b472dc2aceedb1a974b93a3003a81b7e0265963bd2aa0acdcb17598215a4f \
	BITCOIN_ASC_URL=https://bitcoincore.org/bin/bitcoin-core-$BITCOIN_VERSION/SHA256SUMS.asc \
	BITCOIN_PGP_KEY=01EA5486DE18A882D4C2684590C8019E36C2E964

RUN set -ex \
	&& cd /tmp \
	&& wget -qO bitcoin.tar.gz "$BITCOIN_URL" \
	&& echo "$BITCOIN_SHA256 bitcoin.tar.gz" | sha256sum -c - \
	&& gpg --no-tty --keyserver keyserver.ubuntu.com --recv-keys "$BITCOIN_PGP_KEY" \
	&& wget -qO bitcoin.asc "$BITCOIN_ASC_URL" \
	&& gpg --verify bitcoin.asc \
	&& tar -xzvf bitcoin.tar.gz -C /usr/local --strip-components=1 --exclude=*-qt \
	&& rm -rf /tmp/*


FROM debian:stretch-slim
COPY --from=builder /usr/local/bin/bitcoind /usr/local/bin/bitcoin-cli /usr/local/bin/
RUN groupadd -r bitcoin && useradd -r -m -g bitcoin bitcoin \
	&& ln -s /usr/local/bin/bitcoin-cli /usr/local/bin/c

ENV BITCOIN_DATA=/data

# create data directory
RUN mkdir "$BITCOIN_DATA" \
	&& chown -R bitcoin:bitcoin "$BITCOIN_DATA" \
	&& ln -sfn "$BITCOIN_DATA" /home/bitcoin/.bitcoin \
	&& chown -h bitcoin:bitcoin /home/bitcoin/.bitcoin

VOLUME /data

COPY docker-entrypoint.sh /entrypoint.sh

USER bitcoin

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bitcoind"]
