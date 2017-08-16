FROM alexpatel/docker-barrelfish-mips-sys161:latest

ENV PATH=/usr/local/bin:${PATH}
ARG BF_HOME=/usr/local/barrelfish

COPY . ${BF_HOME}
WORKDIR ${BF_HOME}
ENTRYPOINT ["/usr/local/barrelfish/docker/mips_sys161/entrypoint.sh"]
