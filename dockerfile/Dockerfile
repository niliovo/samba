FROM alpine:latest

MAINTAINER niliovo 1791356563@qq.com

ENV TZ=${TZ:-Asia/Shanghai}

ENV m_dir="/"

WORKDIR $m_dir

COPY samba_build.sh $m_dir

COPY samba_startup.sh $m_dir

COPY sample_config.yml $m_dir

RUN chmod a+x $m_dir/samba_build.sh && $m_dir/samba_build.sh

EXPOSE 137/udp 138/udp 139 445

VOLUME [ "/config" ]

ENTRYPOINT [ "/samba_startup.sh" ]
CMD [ "smbd", "-F", "--debug-stdout", "--no-process-group" ]

HEALTHCHECK --interval=30s --timeout=10s \
  CMD smbclient -L \\localhost -U % -m SMB3