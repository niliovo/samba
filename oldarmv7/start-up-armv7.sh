#!/bin/bash

SAMBA_WORKGROUP=${SAMBA_WORKGROUP:-WORKGROUP}
SAMBA_SERVER_STRING=${SAMBA_SERVER_STRING:-SAMBA}
SAMBA_LOG_LEVEL=${SAMBA_LOG_LEVEL:-0}
SAMBA_FOLLOW_SYMLINKS=${SAMBA_FOLLOW_SYMLINKS:-yes}
SAMBA_WIDE_LINKS=${SAMBA_WIDE_LINKS:-yes}
SAMBA_HOSTS_ALLOW=${SAMBA_HOSTS_ALLOW:-0.0.0.0/0 127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16}
#SAMBA_INTERFACES=${SAMBA_INTERFACES:-eth0}

NETBIOS_NAME=${NETBIOS_NAME:-SAMBA}
C_D=${C_D:-/config}
C_S=${C_S:-/samba/sample-config.yml}
C_F=${C_F:-config.yml}

echo "设置时区为 ${TZ}"
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

if [ ! -e "$C_D/$C_F" ]; then
  echo "配置文件不存在，正在生成配置文件"
  cp $C_S $C_D/$C_F
else
  echo "配置文件已存在，请修改配置文件(修改完毕请忽略)"
fi

echo "设置缓存文件夹"
mkdir -p $C_D/cache $C_D/lib $C_D/cache/logs
if [ -z "$(ls -A $C_D/lib)" ]; then
  cp -r /var/lib/samba/* $C_D/lib/
fi
rm -rf /var/lib/cache /var/lib/samba
ln -sf $C_D/cache /var/cache/samba
ln -sf $C_D/lib /var/lib/samba

echo "设置全局配置"
  cat > /etc/samba/smb.conf <<EOL
[global]
workgroup = ${SAMBA_WORKGROUP}
server string = ${SAMBA_SERVER_STRING}
server role = standalone server
server services = -dns, -nbt
server signing = default
server multi channel support = yes
log level = ${SAMBA_LOG_LEVEL}
log file = $C_D/cache/logs/log.%m
max log size = 50
hosts allow = ${SAMBA_HOSTS_ALLOW}
;hosts deny = 0.0.0.0/0
security = user
guest account = nobody
pam password change = yes
map to guest = bad user
usershare allow guests = yes
create mask = 0755
force create mode = 0775
directory mask = 0775
force directory mode = 0775
follow symlinks = ${SAMBA_FOLLOW_SYMLINKS}
wide links = ${SAMBA_WIDE_LINKS}
unix extensions = no
printing = bsd
printcap name = /dev/null
disable spoolss = yes
disable netbios = no
netbios name = ${NETBIOS_NAME}
smb ports = 445
client ipc min protocol = default
client ipc max protocol = default
wins support = yes
;wins server = 0.0.0.0
;wins proxy = yes
dns proxy = no
socket options = TCP_NODELAY
strict locking = no
domain master = yes
local master = yes
preferred master = yes
winbind scan trusted domains = yes
vfs objects = fruit streams_xattr
fruit:metadata = stream
fruit:model = MacSamba
fruit:posix_rename = yes
fruit:veto_appledouble = no
fruit:wipe_intentionally_left_blank_rfork = yes
fruit:delete_empty_adfiles = yes
fruit:time machine = yes
EOL

if [ -n "${SAMBA_INTERFACES}" ]; then
  cat >> /etc/samba/smb.conf <<EOL
interfaces = ${SAMBA_INTERFACES}
bind interfaces only = no
EOL
fi

if [[ "$(yq --output-format=json e '(.. | select(tag == "!!str")) |= envsubst' $C_D/config.yml 2>/dev/null | jq '.auth')" != "null" ]]; then
  for auth in $(yq -j e '(.. | select(tag == "!!str")) |= envsubst' $C_D/config.yml 2>/dev/null | jq -r '.auth[] | @base64'); do
    _jq() {
      echo "${auth}" | base64 --decode | jq -r "${1}"
    }
    password=$(_jq '.password')
    if [[ "$password" = "null" ]] && [[ -f "$(_jq '.password_file')" ]]; then
      password=$(cat "$(_jq '.password_file')")
    fi
    echo "创建用户 $(_jq '.user')/$(_jq '.group') ($(_jq '.uid'):$(_jq '.gid'))"
    id -g "$(_jq '.gid')" &>/dev/null || id -gn "$(_jq '.group')" &>/dev/null || addgroup -g "$(_jq '.gid')" -S "$(_jq '.group')"
    id -u "$(_jq '.uid')" &>/dev/null || id -un "$(_jq '.user')" &>/dev/null || adduser -u "$(_jq '.uid')" -G "$(_jq '.group')" "$(_jq '.user')" -SHD
    echo -e "$password\n$password" | smbpasswd -a -s "$(_jq '.user')"
    unset password
  done
fi

if [[ "$(yq --output-format=json e '(.. | select(tag == "!!str")) |= envsubst' $C_D/config.yml 2>/dev/null | jq '.global')" != "null" ]]; then
  for global in $(yq --output-format=json e '(.. | select(tag == "!!str")) |= envsubst' $C_D/config.yml 2>/dev/null | jq -r '.global[] | @base64'); do
  echo "增加全局选项: $(echo "$global" | base64 --decode)"
  cat >> /etc/samba/smb.conf <<EOL
$(echo "$global" | base64 --decode)
EOL
  done
fi

if [[ "$(yq --output-format=json e '(.. | select(tag == "!!str")) |= envsubst' $C_D/config.yml 2>/dev/null | jq '.share')" != "null" ]]; then
  for share in $(yq --output-format=json e '(.. | select(tag == "!!str")) |= envsubst' $C_D/config.yml 2>/dev/null | jq -r '.share[] | @base64'); do
    _jq() {
      echo "${share}" | base64 --decode | jq -r "${1}"
    }
    echo "创建分享文件夹 $(_jq '.name')"
    if [[ "$(_jq '.name')" = "null" ]] || [[ -z "$(_jq '.name')" ]]; then
      >&2 echo "错误: 需要名称"
      exit 1
    fi
    echo -e "\n[$(_jq '.name')]" >> /etc/samba/smb.conf
    if [[ "$(_jq '.path')" = "null" ]] || [[ -z "$(_jq '.path')" ]]; then
      >&2 echo "错误: 需要路径"
      exit 1
    fi
    echo "path = $(_jq '.path')" >> /etc/samba/smb.conf
    if [[ "$(_jq '.comment')" != "null" ]] && [[ -n "$(_jq '.comment')" ]]; then
      echo "comment = $(_jq '.comment')" >> /etc/samba/smb.conf
    fi
    if [[ "$(_jq '.browsable')" = "null" ]] || [[ -z "$(_jq '.browsable')" ]]; then
      echo "browsable = yes" >> /etc/samba/smb.conf
    else
      echo "browsable = $(_jq '.browsable')" >> /etc/samba/smb.conf
    fi
    if [[ "$(_jq '.readonly')" = "null" ]] || [[ -z "$(_jq '.readonly')" ]]; then
      echo "read only = yes" >> /etc/samba/smb.conf
    else
      echo "read only = $(_jq '.readonly')" >> /etc/samba/smb.conf
    fi
    if [[ "$(_jq '.guestok')" = "null" ]] || [[ -z "$(_jq '.guestok')" ]]; then
      echo "guest ok = yes" >> /etc/samba/smb.conf
    else
      echo "guest ok = $(_jq '.guestok')" >> /etc/samba/smb.conf
    fi
    if [[ "$(_jq '.validusers')" != "null" ]] && [[ -n "$(_jq '.validusers')" ]]; then
      echo "valid users = $(_jq '.validusers')" >> /etc/samba/smb.conf
    fi
    if [[ "$(_jq '.adminusers')" != "null" ]] && [[ -n "$(_jq '.adminusers')" ]]; then
      echo "admin users = $(_jq '.adminusers')" >> /etc/samba/smb.conf
    fi
    if [[ "$(_jq '.writelist')" != "null" ]] && [[ -n "$(_jq '.writelist')" ]]; then
      echo "write list = $(_jq '.writelist')" >> /etc/samba/smb.conf
    fi
    if [[ "$(_jq '.veto')" != "null" ]] && [[ "$(_jq '.veto')" = "no" ]]; then
      echo "veto files = /._*/.apdisk/.AppleDouble/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/" >> /etc/samba/smb.conf
      echo "delete veto files = yes" >> /etc/samba/smb.conf
    fi
    if [[ "$(_jq '.hidefiles')" != "null" ]] && [[ -n "$(_jq '.hidefiles')" ]]; then
      echo "hide files = $(_jq '.hidefiles')" >> /etc/samba/smb.conf
    fi
    if [[ "$(_jq '.recycle')" != "null" ]] && [[ -n "$(_jq '.recycle')" ]]; then
      echo "vfs objects = recycle" >> /etc/samba/smb.conf
      echo "recycle:repository = .recycle" >> /etc/samba/smb.conf
      echo "recycle:keeptree = yes" >> /etc/samba/smb.conf
      echo "recycle:versions = yes" >> /etc/samba/smb.conf
    fi
  done
fi

chmod -R 0755 /var/lib/samba

chmod 0700 /var/lib/samba/private/msg.sock

testparm -s

exec "$@"