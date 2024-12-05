#!/bin/sh

apk --update --no-cache add bash coreutils jq samba shadow tzdata yq bash

cp /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

rm -rf /tmp/*
