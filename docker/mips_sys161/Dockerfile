FROM alexpatel/docker-barrelfish-mips-sys161:latest

ENV PATH=/usr/local/bin:${PATH}
ARG BF_HOME=/usr/local/barrelfish

COPY . ${BF_HOME}
WORKDIR ${BF_HOME}
RUN mkdir -pv results
RUN mkdir -pv build && cd build && ../hake/hake.sh -s .. -a armv7
