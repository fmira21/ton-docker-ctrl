FROM ghcr.io/ton-blockchain/ton:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install --no-install-recommends -y wget gcc libsecp256k1-dev libsodium-dev liblz4-dev python3-dev python3-pip sudo git fio iproute2 plzip pv curl libjemalloc-dev \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/ton-work/db/static /var/ton-work/db/import /var/ton-work/db/keyring

ENV BIN_DIR /usr/local/bin
ARG MYTONCTRL_VERSION=master
ARG TELEMETRY=false
ARG DUMP=false
ARG MODE=validator
ARG IGNORE_MINIMAL_REQS=true
ARG GLOBAL_CONFIG_URL=https://ton.org/global.config.json

RUN wget -nv https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py -O /usr/bin/systemctl  \
    && chmod +x /usr/bin/systemctl \
    && wget https://raw.githubusercontent.com/ton-blockchain/mytonctrl/${MYTONCTRL_VERSION}/scripts/install.sh -O /tmp/install.sh \
    && wget -nv ${GLOBAL_CONFIG_URL} -O ${BIN_DIR}/global.config.json \
    && if [ "$TELEMETRY" = false ]; then export TELEMETRY="-t"; else export TELEMETRY=""; fi && if [ "$IGNORE_MINIMAL_REQS" = true ]; then export IGNORE_MINIMAL_REQS="-i"; else export IGNORE_MINIMAL_REQS=""; fi \
    && ln -s /usr/bin/ton /usr/local/bin/ton \
    && /bin/bash /tmp/install.sh ${TELEMETRY} ${IGNORE_MINIMAL_REQS} -b ${MYTONCTRL_VERSION} -m ${MODE} \
    && ln -sf /proc/$$/fd/1 /usr/local/bin/mytoncore/mytoncore.log \
    && ln -sf /proc/$$/fd/1 /var/log/syslog \
    && sed -i 's/--logname \/var\/ton-work\/log//g; s/--verbosity 1/--verbosity 3/g' /etc/systemd/system/validator.service \
    && sed -i 's/\[Service\]/\[Service\]\nStandardOutput=null\nStandardError=syslog/' /etc/systemd/system/validator.service \
    && sed -i 's/\[Service\]/\[Service\]\nStandardOutput=null\nStandardError=syslog/' /etc/systemd/system/mytoncore.service \
    && rm -rf /var/lib/apt/lists/* && rm -rf /root/.cache/pip

VOLUME ["/var/ton-work", "/usr/local/bin/mytoncore"]
COPY --chmod=755 scripts/entrypoint.sh/ /scripts/entrypoint.sh
ENTRYPOINT ["/scripts/entrypoint.sh"]