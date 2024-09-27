FROM debian:bookworm-slim AS builder

RUN set -ex \
	&& apt-get update \
	&& apt-get install -qq --no-install-recommends ca-certificates wget

ENV BITCOIN_VERSION=25.2
ENV BITCOIN_URL=https://bitcoincore.org/bin/bitcoin-core-$BITCOIN_VERSION/bitcoin-$BITCOIN_VERSION-x86_64-linux-gnu.tar.gz \
	BITCOIN_SHA256=8d8c387e597e0edfc256f0bbace1dac3ad1ebf4a3c06da3e2975fda333817dea

RUN set -ex \
	&& cd /tmp \
	&& wget -qO bitcoin.tar.gz "$BITCOIN_URL" \
	&& echo "$BITCOIN_SHA256 bitcoin.tar.gz" | sha256sum -c - \
	&& tar -xzvf bitcoin.tar.gz -C /usr/local --strip-components=1 --exclude=*-qt


FROM debian:bookworm-slim
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
