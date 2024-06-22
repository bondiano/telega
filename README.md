# Telega

[![Package Version](https://img.shields.io/hexpm/v/telega)](https://hex.pm/packages/telega)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/telega/)

A [Gleam](https://gleam.run/) library for the Telegram Bot API.

## It provides

- an interface to the Telegram Bot HTTP-based APIs `telega/api`
- adapter to use with [wisp](https://github.com/gleam-wisp/wisp)
- session bot implementation
- conversation implementation

## Quick start

> If you are new to Telegram bots, read the official [Introduction for Developers](https://core.telegram.org/bots) written by the Telegram team.

First, visit [@BotFather](https://t.me/botfather) and create a new bot. Copy **the token** and save it for later.

Init new gleam project and add `telega` and `wisp` as a dependency:

```sh
$ gleam new first_tg_bot
$ cd first_tg_bot
$ gleam add telega wisp mist gleam_erlang
```

Replace the `first_tg_bot.gleam` file content with the following code:

```gleam
import gleam/erlang/process
import gleam/option.{None}
import gleam/result
import mist
import telega
import telega/adapters/wisp as telega_wisp
import telega/reply
import telega/update.{CommandUpdate, TextUpdate}
import wisp

fn handle_request(bot, req) {
  use <- telega_wisp.handle_bot(req, bot)
  wisp.not_found()
}

fn echo_handler(ctx) {
  use <- telega.log_context(ctx, "echo")

  case ctx.update {
    TextUpdate(text: text, ..) -> reply.with_text(ctx, text)
    CommandUpdate(command: command, ..) -> reply.with_text(ctx, command.text)
    _ -> Error("No text message")
  }
  |> result.map(fn(_) { Nil })
}

pub fn main() {
  wisp.configure_logger()

  let assert Ok(bot) =
    telega.new(
      token: "your bot token from @BotFather",
      url: "your bot url",
      webhook_path: "secret path",
      secret_token: None,
    )
    |> telega.handle_all(echo_handler)
    |> telega.init_nil_session

  let assert Ok(_) =
    wisp.mist_handler(handle_request(bot, _), wisp.random_string(64))
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http
    |> result.nil_error

  process.sleep_forever()
}
```

Replace `"your bot token from @BotFather"` with the token you got from the BotFather. Set the `url` and `webhook_path` to your server URL and the path you want to use for the webhook. If you don't have a server yet, you can use [ngrok](https://ngrok.com/) or [localtunne](https://localtunnel.me/) to create a tunnel to your local machine.

Then run the bot:

```sh
$ gleam run
```

and it will echo all received text messages.

Congrats! You just wrote a Telegram bot :)

## Examples

Other examples can be found in the [examples](./examples) directory.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```
