#!/bin/sh
exec docker run \
    -v `pwd`/config.toml:/app/config.toml \
    -v `pwd`/db:/app/db \
    -v `pwd`/erl_crash.dump:/app/erl_crash.dump \
    -i -t tgas $@
