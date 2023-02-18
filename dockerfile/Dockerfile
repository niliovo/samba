FROM alpine:latest

MAINTAINER niliovo 1791356563@qq.com

ENV TZ=${TZ:-Asia/Shanghai}

COPY samba_build.sh /

COPY samba_startup.sh /

COPY sample_config.yml /

RUN "chmod 777 /samba_build.sh && chmod 777 /samba_startup.sh"

RUN "/samba_build.sh"

EXPOSE 137/udp 138/udp 139 445

VOLUME [ "/config" ]

ENTRYPOINT [ "/samba_startup.sh" ]
CMD [ "smbd", "-F", "--debug-stdout", "--no-process-group" ]

HEALTHCHECK --interval=30s --timeout=10s \
  CMD smbclient -L \\localhost -U % -m SMB3