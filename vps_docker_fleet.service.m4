changequote({{,}})dnl
define(DOCKER_NAME, something)dnl
define(DOCKER_VOLUME, none)dnl
define(DOCKER_VOLUME_OCTAL_MODE, 1777)dnl
define(DOCKER_REGISTRY, index.docker.io)dnl
define(DOCKER_REPOSITORY, {{cloudposse/ubuntu-vps}})dnl
define(DOCKER_TAG, {{latest}})dnl
define(DOCKER_IMAGE, {{DOCKER_REGISTRY}}/{{DOCKER_REPOSITORY}}:{{DOCKER_TAG}})dnl
define(DOCKER_STOP_TIMEOUT, 20)dnl
define(DOCKER_HOSTNAME, something.vps.ourcloud.local)dnl
define(DOCKER_DNS, ${DNS_SERVER})dnl
define(VPS_SSH_PORT, )dnl
define(VPS_SSH_HOSTNAME, localhost)dnl
define(VPS_USER, {{root}})dnl
define(VPS_GROUP, {{VPS_USER}})dnl
define(VPS_PASSWORD, {{}})dnl
define(VPS_ENABLE_SUDO, {{{{true}}}})dnl
define(VPS_GITHUB_USERS, foobar)dnl
define(DNS_SERVICE_NAME, {{{{vps}}}})dnl
define(DNS_SERVICE_ID, {{{{VPS_USER}}}})dnl

[Unit]
Description=Standalone VPS with Docker & Fleet support ifelse(DOCKER_VOLUME, {{none}}, {{}}, with volumes from {{DOCKER_VOLUME}})
Requires=docker.service
After=docker.service
Requires=flanneld.service
After=flanneld.service

[Service]
User={{core}}
EnvironmentFile=/etc/environment
EnvironmentFile=/etc/env.d/*
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker --debug=true pull DOCKER_IMAGE

ifelse(DOCKER_VOLUME, {{none}}, {{}}, ExecStartPre=/usr/bin/sh -c "echo {{DOCKER_VOLUME}} | cut -d: -f1 | xargs mkdir -p -m {{DOCKER_VOLUME_OCTAL_MODE}}")
ExecStartPre=-/usr/bin/docker stop --time=DOCKER_STOP_TIMEOUT DOCKER_NAME
ExecStartPre=-/usr/bin/docker rm DOCKER_NAME
ExecStart=/usr/bin/docker run \
                          --rm \
                          --name DOCKER_NAME \
                          -v /usr/bin/docker:/usr/bin/docker:ro \
                          -v /var/run/docker.sock:/var/run/docker.sock \
                          -v /var/run/fleet.sock:/var/run/fleet.sock \
                          -v /usr/bin/fleetctl:/usr/bin/fleetctl:ro \
                          ifelse(DOCKER_DNS, {{}}, {{}}, --dns {{DOCKER_DNS}}) \
                          ifelse(DOCKER_HOSTNAME, {{none}}, {{}}, --hostname {{DOCKER_HOSTNAME}}) \
                          ifelse(DOCKER_VOLUME, {{none}}, {{}}, --volume {{DOCKER_VOLUME}}) \
                          -e "{{VPS_USER}}=VPS_USER" \
                          -e "{{VPS_GROUP}}=VPS_GROUP" \
                          -e "{{VPS_ENABLE_SUDO}}=VPS_ENABLE_SUDO" \
                          -e "{{VPS_PASSWORD}}=VPS_PASSWORD" \
                          -e "{{VPS_GITHUB_USERS}}=VPS_GITHUB_USERS" \
                          -e "SERVICE_NAME=DNS_SERVICE_NAME" \
                          -e "SERVICE_ID=DNS_SERVICE_ID" \
                          DOCKER_IMAGE 
ifelse(VPS_SSH_PORT, {{}}, {{}}, ExecStartPost=/usr/bin/etcdctl set /haproxy/tcp/{{VPS_SSH_PORT}}/{{DOCKER_NAME}} "{{VPS_SSH_HOSTNAME}}:22 check port 22 resolvers dns") 

ExecStop=-/usr/bin/docker stop --time=DOCKER_STOP_TIMEOUT DOCKER_NAME
TimeoutStopSec=DOCKER_STOP_TIMEOUT{{s}}

RestartSec=10s
Restart=always


[Install]
WantedBy=multi-user.target
