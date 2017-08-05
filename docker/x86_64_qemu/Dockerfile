FROM alexpatel/docker-barrelfish-qemu-x86_64:latest
ENV PATH=/usr/local/bin:${PATH}
ARG BF_HOME=/usr/local/barrelfish

COPY . ${BF_HOME}
WORKDIR ${BF_HOME}
RUN mkdir -pv results
RUN mkdir -pv build && cd build && ../hake/hake.sh -s .. -a x86_64
RUN cd build && make -j5 X86_64_Basic
