FROM ghcr.io/neodix42/ton:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install --no-install-recommends -y wget gcc libsecp256k1-dev libsodium-dev liblz4-dev python3-dev python3-pip sudo git fio iproute2 plzip pv curl libjemalloc-dev ninja-build rocksdb-tools \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/ton-work/db/static /var/ton-work/db/import /var/ton-work/db/keyring /usr/bin/ton /usr/bin/ton/lite-client /usr/bin/ton/validator-engine /usr/bin/ton/validator-engine-console /usr/bin/ton/utils /usr/src/ton/crypto/fift/lib/ /usr/src/ton/crypto/smartcont /usr/bin/ton/crypto \
    && cd /usr/src/ton && git init && git remote add origin https://github.com/ton-blockchain/ton.git

ARG MYTONCTRL_VERSION=master
ARG TELEMETRY=false
ARG DUMP=false
ARG MODE=validator
ARG IGNORE_MINIMAL_REQS=true
ARG GLOBAL_CONFIG_URL=https://ton.org/global.config.json

RUN cp /usr/local/bin/lite-client /usr/bin/ton/lite-client/ \
    && cp /usr/local/bin/validator-engine /usr/bin/ton/validator-engine \
    && cp /usr/local/bin/validator-engine-console /usr/bin/ton/validator-engine-console/ \
    && cp /usr/local/bin/generate-random-id /usr/bin/ton/utils/ \
    && cp /usr/local/bin/fift /usr/bin/ton/crypto/ \
    && cp /usr/local/bin/func /usr/bin/ton/crypto/ \
    && cp /usr/lib/fift/* /usr/src/ton/crypto/fift/lib/ \
    && cp -r /usr/share/ton/smartcont/* /usr/src/ton/crypto/smartcont/

RUN wget -nv https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py -O /usr/bin/systemctl \
    && chmod +x /usr/bin/systemctl \
    && wget https://raw.githubusercontent.com/ton-blockchain/mytonctrl/${MYTONCTRL_VERSION}/scripts/install.sh -O /tmp/install.sh \
    && wget -nv ${GLOBAL_CONFIG_URL} -O /usr/bin/ton/global.config.json \
    && if [ "$TELEMETRY" = false ]; then export TELEMETRY="-t"; else export TELEMETRY=""; fi && if [ "$IGNORE_MINIMAL_REQS" = true ]; then export IGNORE_MINIMAL_REQS="-i"; else export IGNORE_MINIMAL_REQS=""; fi \
    && /bin/bash /tmp/install.sh ${TELEMETRY} ${IGNORE_MINIMAL_REQS} -b ${MYTONCTRL_VERSION} -m ${MODE} \
    && ln -sf /proc/$$/fd/1 /usr/local/bin/mytoncore/mytoncore.log \
    && ln -sf /proc/$$/fd/1 /var/log/syslog \
    && sed -i 's/--logname \/var\/ton-work\/log//g; s/--verbosity 1/--verbosity 3/g' /etc/systemd/system/validator.service \
    && sed -i 's/\[Service\]/\[Service\]\nStandardOutput=null\nStandardError=syslog/' /etc/systemd/system/validator.service \
    && sed -i 's/\[Service\]/\[Service\]\nStandardOutput=null\nStandardError=syslog/' /etc/systemd/system/mytoncore.service \
    && rm -rf /var/lib/apt/lists/* && rm -rf /root/.cache/pip VOLUME ["/var/ton-work", "/usr/local/bin/mytoncore"]

COPY --chmod=755 scripts/entrypoint.sh/ /scripts/entrypoint.sh

ENTRYPOINT ["/scripts/entrypoint.sh"]