FROM ubuntu:xenial
ENV PATH=/usr/local/bin:${PATH}
ARG BF_HOME=/usr/local/barrelfish
COPY . ${BF_HOME}
WORKDIR ${BF_HOME}
RUN pwd && echo ${BF_HOME}
RUN ${BF_HOME}/fvp/install.sh
CMD /bin/bash
