#!/bin/sh

sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories &&

apk --update --no-cache add bash coreutils jq samba shadow tzdata yq bash

cp /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

rm -rf /tmp/*
