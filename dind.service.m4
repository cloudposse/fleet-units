changequote({{,}})dnl
define(DOCKER_NAME, {{docker-in-docker}})dnl
define(DOCKER_REGISTRY, index.docker.io)dnl
define(DOCKER_REPOSITORY, {{{{docker}}}})dnl
define(DOCKER_TAG, {{dind}})dnl
define(DOCKER_IMAGE, {{DOCKER_REGISTRY}}/{{DOCKER_REPOSITORY}}:{{DOCKER_TAG}})dnl
define(DOCKER_STOP_TIMEOUT, 20)dnl
define(DOCKER_VOLUME, )dnl
define(DOCKER_VOLUME_OCTAL_MODE, 1777)dnl
define(DOCKER_DNS, ${DNS_SERVER})dnl
define(DOCKER_DNS_SEARCH, )dnl
define(DOCKER_MEMORY, 3500m)dnl
define(DOCKER_CPU_SHARES, 100)dnl
define(DOCKER_OPTS, {{docker daemon --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375  --storage-driver=overlay --insecure-registry=registry.docker}})dnl
dnl define(DOCKER_OPTS, {{docker daemon --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375  --insecure-registry=registry.docker}})dnl
define(FLEET_GLOBAL_SERVICE, {{false}})dnl
define(DNS_SERVICE_NAME, {{{{docker}}}})dnl
define(DNS_SERVICE_ID, {{{{registry}}}})dnl

[Unit]
Description=Docker Registry
Requires=docker.service
After=docker.service
Requires=flanneld.service
After=flanneld.service

[Service]
User=core
EnvironmentFile=/etc/environment
EnvironmentFile=/etc/env.d/*
TimeoutStartSec=0
ifelse(DOCKER_VOLUME, {{none}}, {{}}, ExecStartPre=/usr/bin/sh -c "echo {{DOCKER_VOLUME}} | cut -d: -f1 | xargs mkdir -p -m {{DOCKER_VOLUME_OCTAL_MODE}}")
ExecStartPre=-/usr/bin/docker stop --time=DOCKER_STOP_TIMEOUT DOCKER_NAME
ExecStartPre=-/usr/bin/docker rm DOCKER_NAME
ExecStartPre=-/usr/bin/docker --debug=true pull DOCKER_IMAGE
ExecStart=/usr/bin/docker run \
                              --name DOCKER_NAME \
                              --rm \
                              --volume /usr/local/bin/ \
                              --volume /tmp/ \
                              --privileged \
                              ifelse(DOCKER_MEMORY, {{}}, {{}}, --memory={{DOCKER_MEMORY}}) \
                              ifelse(DOCKER_CPU_SHARES, {{}}, {{}}, --cpu-shares={{DOCKER_CPU_SHARES}}) \
                              ifelse(DOCKER_DNS, {{}}, {{}}, --dns={{DOCKER_DNS}}) \
                              ifelse(DOCKER_DNS_SEARCH, {{}}, {{}}, --dns-search={{DOCKER_DNS_SEARCH}}) \
                              ifelse(DOCKER_VOLUME, {{}}, {{}}, --volume {{DOCKER_VOLUME}}) \
                              -e "SERVICE_NAME=DNS_SERVICE_NAME" \
                              -e "SERVICE_ID=DNS_SERVICE_ID" \
                              DOCKER_IMAGE \
                              DOCKER_OPTS

# Deregister the service
ExecStop=/usr/bin/docker stop --time=DOCKER_STOP_TIMEOUT DOCKER_NAME
ExecStopPost=-/usr/bin/docker rm DOCKER_NAME
TimeoutStopSec=DOCKER_STOP_TIMEOUT{{s}}

Restart=always
RestartSec=30s

[Install]
WantedBy=multi-user.target

[X-Fleet]
Global=FLEET_GLOBAL_SERVICE
