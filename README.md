# Tgas

Telegram antispam

## Description

Remove spam messages and chats with spammers, logging them in the process, saving spam messages and spamming users info to dedicated spam chat if configured.

## Configuration

Take a look at `config/secret.exs.sample`. Copy it to `config/secret.exs`, fill in the details.

`:tdlib db_dir` is in important place where `tdlib` data will be stored, it is important to keep it secure as anyone who fetches it will have full access to your Telegram account.

## Installation

Have `libtdjson.so` from [tdlib](https://github.com/tdlib/td) installed in your library path.

Have [Rust](https://rustup.rs/) installed.

Have [Elixir](https://elixir-lang.org/) installed.

    $ cd tgas
    $ mix deps.get
    $ MIX_ENV=prod mix release

Now `./_build/prod/rel/tgas` will have your release unpacked, and
`_build/prod/rel/tgas/releases/0.1.0/tgas.tar.gz` (assuming your release version is `0.1.0`)
is the location deployable archive, with `bin/tgas` being runner script.

## Authorization

You'll need to authorize first. Once done authorization will not be needed anymore provided your `:tdlib db_dir` is not deleted.

    $ tgas console
    > :tdlib.phone_number :tgas, "+12345678"
    > :tdlib.auth_code :tgas, "23456"
    > :tdlib.auth_password :tgas, "yourPassword"

## Running

Just use `bin/tgas` in your release. You can use it to run it daemonized, in foreground or
with `IEx` console attached; also you can connect (see `remote_console` command) to
already running instance. Run without arguments to see available options.
