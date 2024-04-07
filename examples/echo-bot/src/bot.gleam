import gleam/erlang/process
import gleam/result
import gleam/option.{None, Some}
import mist
import wisp
import telega
import telega/adapters/wisp as telega_wisp
import telega/api as telega_api

fn handle_request(bot, req) {
  use <- telega_wisp.handle_bot(req, bot)
  wisp.not_found()
}

fn echo_handler(ctx) {
  use <- telega.log_context(ctx, "echo")

  case ctx.message.raw.text {
    Some(text) ->
      telega_api.reply(ctx, text)
      |> result.map(fn(_) { Nil })
    None -> Error("No text in message")
  }
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
