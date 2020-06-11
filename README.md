# Tgas

Telegram antispam

## Description

Remove spam messages and chats with spammers, logging them in the process, saving spam messages and senders info to dedicated spam chat if so configured.

## Configuration

Take a look at `config.toml.sample`. Copy it somewhere as `config.toml`, fill in the details.
You'll need `api_id` and `api_hash` from [my.telegram.org](https://my.telegram.org).

## Running in docker

Docker image built with provided `Dockerfile` has following mount points:

1. `/app/db` — tdlib database, including but not limited to authorization data
2. `/app/config.toml` — your configuration
3. `/app/erl_crash.dump` — crash dump if needed (optional)
4. `/app/log` — some logs (optional)

### Building

    docker build -t tgas .

or

    ./build.sh

## First run, authorization

    docker run \
      -v `pwd`/config.toml:/app/config.toml \
      -v `pwd`/db:/app/db \
      -i -t tgas \
      start_iex

or

    ./run.sh start_iex

You need to authorize

    iex> :tdlib.phone_number :tgas, "+12345678"
    iex> :tdlib.auth_code :tgas, "23456"
    iex> :tdlib.auth_password :tgas, "yourPassword"

You can also list your chats here

    iex> Tgas.Session.getChats

... or find some specific chat by title, using regular expression

    iex> Tgas.Session.findChat ~r/secret group/i

## Running

    docker run \
      -v `pwd`/config.toml:/app/config.toml \
      -v `pwd`/db:/app/db \
      -i -t tgas

or

    ./run.sh

For options run

    ./run.sh help
