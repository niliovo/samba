# samba_docker

- [中文](./README.md)
- [ENGLISH](./README_EN.md)

- [Github](https://github.com/niliovo/samba_docker)
- [Docker Hub](https://hub.docker.com/r/niliaerith/samba)

# 本项目基于下列项目,部署samba到docker容器,镜像基于Alpine

- [docker-samba](https://github.com/crazy-max/docker-samba)

## Docker-Cli使用指南


```sh
docker run -itd --name samba --hostname samba --net host --restart always -v /your_path/samba/config:/config -e PUID=0 -e PGID=0 -e TZ=Asia/Shanghai -e IP_ADDR=your_ip --privileged=true niliaerith/samba:latest

```

## Docker Compose使用指南

```compose.yml
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

## 变量

> 必须变量
- `/your_path/samba/config:/config` 
- - `/your_path/samba/config`目录为配置文件目录,默认配置文件为`config.yml`，第一次运行自动生成，请自行修改,配置文件参数看[这里](##配置文件)

> 可选变量
- `TZ=Asia/Shanghai`
- - `TZ`为时区,默认为`Asia/Shanghai`
- `IP_ADDR=your_ip`
- - `your_ip`修改为你的ip地址或域名,开启此选项后可在Windows平台发现samba服务

## 配置文件

> 配置文件会在第一次运行生成,位于容器内`/config/config.yml`,映射到宿主机位置为`/your_path/samba/config/config.yml`,修改完配置文件后重启容器生效,`docker restart samba`

```yml
auth:
  - user: admin # 用户名
    group: admin # 组
    uid: 1000 # 用户 uid
    gid: 1000 # 组 gid
    password: password # 密码
    #password_file: /your_path/secrets/password # 密码文件位置
  - user: guest
    group: guest
    uid: 405
    gid: 100
    password: guest

global:
  - "force user = admin,guest" # 管理员用户
  - "force group = admin,guest" # 管理员组

share:
  - name: share # 共享目录名
    comment: Description # 共享描述
    path: /your_path/share # 共享路径
    browsable: yes # 是否可见，若为`no`则必须手动输入路径访问
    readonly: no # 是否只读
    guestok: yes # 是否允许访客
    validusers: admin,guest # 允许访问用户
    writelist: admin,guest # 白名单,白名单用户拥有写入权限
    veto: yes # 是不可见或不可访问的预定义文件和目录的列表
    hidefiles: /_*/ # 隐藏文件
    recycle: yes # 是否启用回收站
```

## 支持平台

- amd64
- 386/32
- arm64
- arm/v7

# 感谢

- [docker-samba](https://github.com/crazy-max/docker-samba)
- [GitHub](https://github.com/)
- [Docker Hub](https://hub.docker.com/)
- [中科大源](https://mirrors.ustc.edu.cn/)
