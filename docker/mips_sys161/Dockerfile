FROM alexpatel/docker-barrelfish-mips-sys161:latest

ENV PATH=/usr/local/bin:${PATH}
ARG BF_HOME=/usr/local/barrelfish

COPY . ${BF_HOME}
RUN mkdir -pv ${BF_HOME}/build
WORKDIR ${BF_HOME}/build
RUN ls -a
