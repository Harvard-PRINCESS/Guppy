FROM alexpatel/docker-barrelfish-gem5-armv7:latest
ENV PATH=/usr/local/bin:${PATH}
ARG BF_HOME=/usr/local/barrelfish
ENV M5_PATH=/gem5

COPY . ${BF_HOME}
WORKDIR ${BF_HOME}
RUN mkdir -pv results
RUN mkdir -pv build && cd build && ../hake/hake.sh -s .. -a armv7
