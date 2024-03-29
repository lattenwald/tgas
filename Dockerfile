# tdlib build
FROM alpine:3.17 AS build-tdlib

RUN apk add --no-cache \
    linux-headers \
    gperf \
    alpine-sdk \
    openssl-dev \
    git \
    cmake \
    zlib-dev

WORKDIR /tmp/_build_tdlib/

RUN git clone -n https://github.com/tdlib/td.git /tmp/_build_tdlib/
RUN git checkout d581e0499a534a2b98474843289e2a77e15a1d2d # v1.8.8 2022-11-25

RUN mkdir build
WORKDIR /tmp/_build_tdlib/build/

RUN cmake -DCMAKE_BUILD_TYPE=Release ..
RUN cmake --build .
RUN make install


# tgas build
FROM alpine:3.17 AS build-tgas

COPY --from=build-tdlib /usr/local/lib/libtd* /usr/local/lib/

RUN apk add --no-cache \
    erlang \
    elixir \
    rust \
    cargo \
    git

ADD . /app
WORKDIR /app
RUN rm -rf _build deps config/local.exs

ENV MIX_ENV prod
RUN mix do local.hex --force, local.rebar --force
RUN mix deps.get
RUN mix do deps.compile, compile, release


# tgas
FROM alpine:3.17

RUN apk add --no-cache \
    gcc \
    g++ \
    ncurses

COPY --from=build-tdlib /usr/local/lib/libtd* /usr/local/lib/

RUN mkdir /app
WORKDIR /app
COPY --from=build-tgas /app/release/prod-*.tar.gz /app/
RUN tar xzf prod-*.tar.gz

VOLUME ["/app/config.toml", "/app/db", "/app/erl_crash.dump", "/app/log"]

ENTRYPOINT ["/app/bin/prod"]
CMD ["start"]
