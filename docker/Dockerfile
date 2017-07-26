FROM ubuntu:xenial
ENV PATH=/usr/local/bin:${PATH}

COPY ./install.sh /install.sh
RUN /install.sh \
    --no-interactive \
    --i-agree-to-the-contained-eula \
    --skip-menu-install \
    -d /fvp \
    --show-files \
#   --quiet \
CMD /bin/bash
