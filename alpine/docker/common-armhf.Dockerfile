FROM evocloud/alpine-base:3.3-armhf
RUN apk update && apk add bash curl zip && rm -fr /var/cache/apk/*
LABEL architecture=armhf
