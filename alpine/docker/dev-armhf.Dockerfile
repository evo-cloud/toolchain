FROM evocloud/alpine:3.3-armhf
RUN echo http://nl.alpinelinux.org/alpine/v3.3/community >>/etc/apk/repositories && \
    apk update && \
    apk add git build-base clang cmake docker && \
    rm -fr /var/cache/apk/*
LABEL architecture=armhf
