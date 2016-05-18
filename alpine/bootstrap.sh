#!/bin/bash

set -ex

ARCH=$1
test -n "$ARCH"

VERSION=$2
test -n "$VERSION" || VERSION=3.3

: ${MIRROR:=nl.alpinelinux.org}

OUT=out
TMP=tmp/$ARCH
URLBASE=http://$MIRROR/alpine/v$VERSION
ROOTFS=$TMP/rootfs
QEMU_ARCH=

fail() {
    echo "$@"
    exit 1
}

get-apk() {
    local arch=$ARCH pkg=$1 path=$2

    local tmpdir="$TMP/$path" repo=main
    local urlbase="$URLBASE/$repo/$arch"

    mkdir -p "$tmpdir"
    curl -sSL "$urlbase/APKINDEX.tar.gz" | tar -C "$TMP" -xz

    local name version
    set +x
    while read; do
        test -n "$REPLY" || name=""
        case "${REPLY:0:1}" in
            P)
                name="${REPLY:2}"
                ;;
            V)
                if [ "$pkg" == "$name" ]; then
                    version="${REPLY:2}"
                    break
                fi
                ;;
        esac
    done <"$TMP/APKINDEX"
    set -x

    if [ -n "$version" ]; then
        curl -sSL "$urlbase/$pkg-$version.apk" | tar -C "$tmpdir" -xz
    else
        echo "$pkg not found" >&2
        return 1
    fi
}

get-qemu() {
    case "$ARCH" in
        arm*) QEMU_ARCH=arm ;;
        x86|i?86) QEMU_ARCH=i386 ;;
        x86_64) return ;;
        *) fail "architecture $ARCH not supported" ;;
    esac

    local url=https://github.com/multiarch/qemu-user-static/releases/download/v2.5.0/x86_64_qemu-${QEMU_ARCH}-static.tar.xz
    curl -sSL "$url" | tar -C "$TMP" -xJ
    mkdir -p $ROOTFS/usr/bin
    cp -f $TMP/qemu-$QEMU_ARCH-static $ROOTFS/usr/bin/
}

qemu-user() {
    if [ -n "$QEMU_ARCH" ]; then
        $TMP/qemu-$QEMU_ARCH-static "$@"
    else
        $@
    fi
}

cross-apk() {
    qemu-user $TMP/sbin/apk.static --root=$ROOTFS --arch=$ARCH --allow-untrusted -v $@
}

rm -fr "$TMP" "$OUT/$ARCH"
get-apk apk-tools-static
get-qemu
mkdir -p $ROOTFS/etc/apk
echo "$URLBASE/main" >$ROOTFS/etc/apk/repositories
cross-apk add --initdb
cross-apk update
cross-apk add alpine-base
mkdir -p $OUT/$ARCH
cp -f docker/base-$ARCH.Dockerfile $OUT/$ARCH/Dockerfile
tar -C $ROOTFS -czf $OUT/$ARCH/alpine-base-$VERSION-$ARCH.tar.gz .
rm -fr "$TMP"
