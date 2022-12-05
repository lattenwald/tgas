#!/bin/sh
exec docker run \
    --network host \
    -v `pwd`/config.toml:/app/config.toml \
    -v `pwd`/db:/app/db \
    --name tgas --rm \
    -i -t tgas $@
