# Samba

- [中文](./README.md)
- [ENGLISH](./README-EN.md)

- [Github](https://github.com/niliovo/samba)
- [Docker Hub](https://hub.docker.com/r/niliaerith/samba)

## Project Introduction

samba is deployed to a docker container, mirroring Alpine

***This project is based on the following items, if there is infringement, please contact to delete***

- [docker-samba](https://github.com/crazy-max/docker-samba)

### Support Platform

- x86_64
- arm64
- x86_32(untested)
- arm32(untested)

> Tip: Multi-platform image simulates different platform compilations for QEMU, there may be problems, if the image is not available, try compiling it yourself

## Usage Introduction

### Docker Compose

```
  samba:
    image: niliaerith/samba:latest
    container_name: samba
    hostname: samba
    restart: always
    network_mode: host
    #ports:
    #  - 137:137/udp
    #  - 138:138/udp
    #  - 139:139
    #  - 445:445
    volumes:
      - /your_path/samba/config:/config
    environment:
      - PUID=0
      - PGID=0
      - TZ=Asia/Shanghai
      - IP_ADDR=your_ip
    privileged: true
```

### Docker Cli

```
docker run -itd --name samba --hostname samba --net host --restart always -v /your_path/samba/config:/config -e PUID=0 -e PGID=0 -e TZ=Asia/Shanghai -e IP_ADDR=your_ip --privileged=true niliaerith/samba:latest
```

### Self Compilation

```
git clone https://github.com/niliovo/samba.git
cd samba
docker build -t samba .
# Replace the above image 'niliaerith/samba' with 'samba'
```

### variable

> Necessary Variable
- `/your_path/samba/config:/config` 
- - The `/your_path/samba/config` directory is the configuration file directory. ,The default configuration file is `config.yml`, It will auto generate when first run, Please modify the configuration file by yourself. See configuration file parameters

> Optional Variable
- `TZ=Asia/Shanghai`
- - `TZ` Is the timezone,The default option is `Asia/Shanghai`
- `IP_ADDR=your_ip`
- - Change `your_ip` to your ip address or domain name, If enable this option to discover samba services on Windows platforms

### Configuration file

> The configuration file is generated on the first run and is located in the container `/config/config.yml`,Mapping to the host is `/your_path/samba/config/config.yml`, After modifying the configuration file, restart the container for the modification to take effect,`docker restart samba`

```yml
auth:
  - user: admin # User name
    group: admin # Group
    uid: 1000 # User uid
    gid: 1000 # Group gid
    password: password # Password
    #password_file: /your_path/secrets/password # Password file path
  - user: guest
    group: guest
    uid: 405
    gid: 100
    password: guest

global:
  - "force user = admin,guest" # Administrator user
  - "force group = admin,guest" # Administrator group

share:
  - name: share # Shared directory name
    comment: Description # Shared description
    path: /your_path/share # Shared path
    browsable: yes # Whether to visible. If it is `no` , you must manually enter the path for access
    readonly: no # Whether to read only
    guestok: yes # Whether visitors are allowed
    validusers: admin,guest # Permitted access user
    writelist: admin,guest # Whitelist: The whitelist user has the write permission
    veto: yes # Is a list of predefined files and directories that are not visible or accessible
    hidefiles: /_*/ # Hidden file
    recycle: yes # Whether to enable the recycle bin
```

## Thanks

- [docker-samba](https://github.com/crazy-max/docker-samba)
- [GitHub](https://github.com/)
- [Docker Hub](https://hub.docker.com/)

## Star History

<a href="https://star-history.com/#niliovo/samba&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=niliovo/samba&type=Date&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=niliovo/samba&type=Date" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=niliovo/samba&type=Date" />
  </picture>
</a>
