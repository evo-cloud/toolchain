FROM evocloud/alpine-base:3.3-x86_64
RUN apk update && apk add bash curl zip && rm -fr /var/cache/apk/*
LABEL architecture=x86_64
