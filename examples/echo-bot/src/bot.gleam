import gleam/erlang/process
import gleam/result.{try}
import gleam/option.{None, Some}
import gleam/erlang/os
import dotenv_gleam
import mist
import wisp.{type Request, type Response}
import telega
import telega/bot.{type Bot, type Context, HandleAll}
import telega/adapters/wisp as telega_wisp
import telega/api as telega_api

fn middleware(
  req: Request,
  bot: Bot,
  handle_request: fn(Request) -> Response,
) -> Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use <- telega_wisp.handle_bot(req, bot)
  use req <- wisp.handle_head(req)
  handle_request(req)
}

fn handle_request(bot: Bot, req: Request) -> Response {
  use req <- middleware(req, bot)

  case wisp.path_segments(req) {
    ["helath"] -> wisp.ok()
    _ -> wisp.not_found()
  }
}

fn echo_handler(ctx: Context) {
  use <- telega.log_context(ctx, "echo")

  case ctx.message.raw.text {
    Some(text) ->
      telega_api.reply(ctx, text)
      |> result.map(fn(_) { Nil })
    None -> Error("No text in message")
  }
}

fn build_bot() -> Result(Bot, Nil) {
  use bot_token <- try(os.get_env("BOT_TOKEN"))
  use webhook_path <- try(os.get_env("WEBHOOK_PATH"))
  use server_url <- try(os.get_env("SERVER_URL"))
  use secret_token <- try(os.get_env("BOT_SECRET_TOKEN"))

  bot.new(
    token: bot_token,
    url: server_url,
    webhook_path: webhook_path,
    secret_token: Some(secret_token),
  )
  |> bot.add_handler(HandleAll(echo_handler))
  |> Ok
}

pub fn main() {
  dotenv_gleam.config()
  wisp.configure_logger()

  use bot <- try(build_bot())
  let secret_key_base = wisp.random_string(64)
  use _ <- try(
    wisp.mist_handler(handle_request(bot, _), secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http
    |> result.nil_error,
  )

  case telega_api.set_webhook(bot) {
    Ok(_) -> wisp.log_info("Webhook set successfully")
    Error(e) -> wisp.log_error("Failed to set webhook: " <> e)
  }

  process.sleep_forever()

  Ok(Nil)
}
